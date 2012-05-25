#!/usr/bin/env jruby19

require_relative 'job_log_parser'
require_relative 'configure'
require 'java'
require 'mongo'
require 'scanf'
require 'gorillib/hash/slice'
require 'thread'
require 'open-uri'

module Vayacondios

  class HadoopMonitor
    include JobLogParser
    include Configurable

    IFSTAT_READ_BUF_SIZE = 0x10000
    SLEEP_SECONDS = 1
    MONGO_JOBS_DB = 'job_info'
    MONGO_JOB_LOGS_COLLECTION = 'job_logs'
    MONGO_MACHINE_STATS_COLLECTION = 'machine_stats'

    def initialize
      self.class.configure_hadoop_jruby
      conf = self.class.get_hadoop_conf
      jconf = Java::org.apache.hadoop.mapred.JobConf.new conf

      # Using the other constructors of JobClient causes null pointer
      # exceptions, apparently due to Cloudera patches.
      loop do
        begin
          @job_client = Java::org.apache.hadoop.mapred.JobClient.new jconf
        rescue NativeException => e
          if e.to_s.start_with? "java.net.ConnectException"
            puts "Couldn't contact job tracker. retrying in 10 seconds."
            sleep 10
            next
          else
            raise
          end
        end
        break
      end
      
      @running_jobs = JobList.new
      @conn = Mongo::Connection.new
      @db = @conn[MONGO_JOBS_DB]
      @job_logs = @db[MONGO_JOB_LOGS_COLLECTION]
      @machine_stats = @db[MONGO_MACHINE_STATS_COLLECTION]
      @trackers = {}
    end

    def run
      loop do

        # Launch threads to watch running jobs for events.
        @job_client.get_all_jobs.select do |job_status|
          job_status.get_run_state ==
            Java::org.apache.hadoop.mapred.JobStatus::RUNNING
        end.each do |job_status|
          job = @job_client.get_job job_status.get_job_id

          unless @running_jobs[job]
            Thread.new(job, @job_logs, @running_jobs) do |*args|
              self.class.watch_job_events *args
            end
          end
        end

        # If there are hadoop jobs running, listen to stats for all
        # machines listed as task trackers.
        if @running_jobs.empty?
          @trackers.values.each{|t| t.kill}
          @trackers = {}
          sleep SLEEP_SECONDS
        else
          # Grab all trackers
          trackers = @job_client.get_cluster_status(true).
            get_active_tracker_names.map{|t| t[/ip(-\d+){4}\.ec2\.internal/]}
          # Launch threads to listen to new ones
          (trackers - @trackers.keys).each do |t|
            @trackers[t] = Thread.new(conf,
                                      t,
                                      @machine_stats,
                                      @running_jobs) do |*args|
              self.class.monitor_tracker *args
            end
          end
          # Close connections to old ones and forget about them.
          @trackers.slice(*(@trackers.keys - trackers)).each{|t| t.kill}
          @trackers.select!{|k,| trackers.index k}
        end
      end
    end

    private

    #
    # watches for job events and records information as appropriate.
    #
    # This is a class method to make it clear what state threads are
    # sharing. According to the mongo-ruby-driver documentation, that
    # gem is thread-safe, so it should be safe to share.
    #
    def self.watch_job_events job, coll, running_jobs
      begin
        running_jobs.add job

        host_port = job.get_tracking_url[/^(http:\/\/)?[^\/]*/]
        job_id = job.get_id.to_s
        conf_uri = "#{host_port}/logs/#{job_id}_conf.xml"
        
        properties = JobLogParser.parse_properties(open conf_uri)

        output_dir = properties["mapred_output_dir"]

        puts "waiting until #{job.get_id.to_s} is complete"
        job.wait_for_completion
        puts "#{job.get_id.to_s} is complete!"

        JobLogParser.parse_log_dir(output_dir, properties).each do |e|
          coll.insert e
        end

        puts "Done writing updating logs for #{job.get_id.to_s}."
      rescue Exception => e
        # Ruby rescues exceptions and fails silently in
        # threaded code, which is not the behavior we want.
        puts e
        puts e.backtrace
        raise
      ensure
        running_jobs.del job
      end
    end

    #
    # Opens a connection to machine_monitor on the task tracker and
    # logs its stats to mongo.
    #
    def self.monitor_tracker conf, hostname, coll, running_jobs
      socket = TCPSocket.open hostname, conf[STAT_SERVER_PORT]
      loop do
        coll.insert \
        :_id => "#{hostname}:#{Time.now.to_i}",
        :timestamp => Time.now.to_i,
        :hostname => hostname,
        :running_jobs => running_jobs.all.map{|j| j.get_id.to_s},
        :stats => JSON.parse(socket.readline)
      end
    end

    #
    # provides basic Hash operations in a thread-safe manner.
    #
    class JobList
      def initialize
        @job_list = {}
        @job_list_lock = Mutex.new
      end

      def add job
        @job_list_lock.synchronize { @job_list[job.get_id.to_s] = job }
      end

      def all
        @job_list_lock.synchronize { @job_list.values }
      end
      
      def del job
        @job_list_lock.synchronize { @job_list.delete job.get_id.to_s}
      end

      def empty?
        @job_list_lock.synchronize { @job_list.empty? }
      end

      def [] job
        @job_list_lock.synchronize { @job_list[job.get_id.to_s] }
      end
    end

    def self.configure_hadoop_jruby
      hadoop_home = ENV['HADOOP_HOME']

      raise "\nHadoop installation not found. Try setting $HADOOP_HOME\n" unless
        (hadoop_home and (File.exist? hadoop_home))

      $CLASSPATH << File.join(File.join(hadoop_home, 'conf') ||
                              ENV['HADOOP_CONF_DIR'],
                              '') # add trailing slash
      
      Dir["#{hadoop_home}/{hadoop*.jar,lib/*.jar}"].each{|jar| require jar}

      begin
        require 'java'
      rescue LoadError => e
        raise "\nJava not found. Are you sure you're running with JRuby?\n" +
          e.message
      end
    end

    def self.get_hadoop_conf
      conf = Java::org.apache.hadoop.conf.Configuration.new

      # per-site defaults
      %w[capacity-scheduler.xml core-site.xml hadoop-policy.xml
       hadoop-site.xml hdfs-site.xml mapred-site.xml].each do |conf_file|
        conf.addResource conf_file
      end
      conf.reload_configuration

      # per-user overrides
      if Swineherd.config[:aws]
        conf.set("fs.s3.awsAccessKeyId",Swineherd.config[:aws][:access_key])
        conf.set("fs.s3.awsSecretAccessKey",Swineherd.config[:aws][:secret_key])

        conf.set("fs.s3n.awsAccessKeyId",Swineherd.config[:aws][:access_key])
        conf.set("fs.s3n.awsSecretAccessKey",Swineherd.config[:aws][:secret_key])
      end

      conf
    end
  end
end  

Vayacondios::HadoopMonitor.new.run
