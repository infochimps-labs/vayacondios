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

    def initialize
      get_conf

      logger.debug "Setting up jruby"
      self.class.configure_hadoop_jruby
      logger.debug "Getting hadoop configuration"
      hadoop_conf = self.class.get_hadoop_conf
      logger.debug "Connecting to Hadoop"
      jconf = Java::org.apache.hadoop.mapred.JobConf.new hadoop_conf

      @running_jobs = JobList.new

      logger.debug "Creating job_logs and job_events mongo collections."
      @conn = Mongo::Connection.new
      @db = @conn[get_conf[MONGO_JOBS_DB]]
      @job_logs = @db.create_collection(get_conf[MONGO_JOB_LOGS_COLLECTION],
                                        :capped => true,
                                        :size => get_conf[JOB_LOGS_SIZE])

      # After we create the job_events database, one of the machine
      # monitors will create the machine stats databse.
      @job_events = @db.create_collection(get_conf[MONGO_JOB_EVENTS_COLLECTION],
                                          :capped => true,
                                          :size => get_conf[JOB_EVENTS_SIZE])

      logger.debug "Waiting for machine_monitor to create mongo_stats collection."
      sleep get_conf[SLEEP_SECONDS] until
        @db.collection_names.index get_conf[MONGO_MACHINE_STATS_COLLECTION]

      @machine_stats = @db[get_conf[MONGO_MACHINE_STATS_COLLECTION]]
      @trackers = {}

      # Using the other constructors of JobClient causes null pointer
      # exceptions, apparently due to Cloudera patches.
      @job_client = Java::org.apache.hadoop.mapred.JobClient.new jconf

      logger.debug "Done with initialization"
    end

    def run
      loop do
        
        logger.debug "In main event loop."

        # Launch threads to watch running jobs for events.
        @job_client.get_all_jobs.select do |job_status|
          job_status.get_run_state ==
            Java::org.apache.hadoop.mapred.JobStatus::RUNNING
        end.each do |job_status|
          job = @job_client.get_job job_status.get_job_id

          unless @running_jobs[job]
            logger.debug "New job: #{job.get_id_to_s}"

            # Report the cluster beginning to work. We must do this in a
            # critical section or two threads may both report the same
            # event.
            @running_jobs.synchronize do
              if @running_jobs.empty?
                logger.debug "Cluster just started working. logging event."
                @job_events.insert(EVENT => CLUSTER_WORKING,
                                   TIME => Time.now.to_i)
              end
              @running_jobs.add job
            end
            Thread.new(job, @job_logs, @job_events, @running_jobs) do |*args|
              self.class.watch_job_events *args
            end
          end
        end

        sleep get_conf[SLEEP_SECONDS]

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
    def self.watch_job_events job, job_logs, job_events, running_jobs
      begin
        host_port = job.get_tracking_url[/^(http:\/\/)?[^\/]*/]
        job_id = job.get_id.to_s
        conf_uri = "#{host_port}/logs/#{job_id}_conf.xml"
        
        properties = JobLogParser.parse_properties(open conf_uri)

        output_dir = properties["mapred_output_dir"]

        puts "waiting until #{job.get_id.to_s} is complete"
        job.wait_for_completion
        puts "#{job.get_id.to_s} is complete!"

        JobLogParser.parse_log_dir(output_dir, properties).each do |e|
          job_logs.insert e
        end

        puts "Done writing updating logs for #{job.get_id.to_s}."
      rescue Exception => e
        # Ruby rescues exceptions and fails silently in
        # threaded code, which is not the behavior we want.
        puts e
        puts e.backtrace
        raise
      ensure
        # Report the cluster finishing all jobs. We must do this in a
        # critical section or two threads may both report the same
        # event.
        running_jobs.synchronize do
          running_jobs.del job
          if running_jobs.empty?
            logger.debug "Cluster went quiet. logging event.:"
            job_events.insert(EVENT => CLUSTER_QUIET,
                              TIME => Time.now.to_i)
          end
        end
      end
    end

    #
    # provides basic Hash operations in a thread-safe manner.
    #
    class JobList
      def initialize
        @job_list = {}
        @job_list_lock = Mutex.new

        # To prevent deadlock, @job_list_lock should always be locked
        # *after* this lock, never before. It is designed to
        # encapsulate code that must lock and release @job_list_lock
        # multiple times. It is necessary (I think) because Ruby locks
        # are non-reentrant.
        @synchronize_block_lock = Mutex.new
      end

      #
      # Executes a critical section
      #
      def synchronize &blk
        @synchronize_block_lock.synchronize &blk
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
