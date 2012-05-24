#!/usr/bin/env jruby

require_relative 'job_log_parser'
require_relative 'machine_monitor'
require 'swineherd-fs'
require 'java'
require 'mongo'
require 'scanf'
require 'gorillib/hash/slice'

module Vayacondios

  class HadoopMonitor

    include JobLogParser

    IFSTAT_READ_BUF_SIZE = 0x10000
    SLEEP_SECONDS = 1
    MONGO_JOBS_DB = 'job_info'
    MONGO_JOB_LOGS_COLLECTION = 'job_logs'
    MONGO_MACHINE_STATS_COLLECTION = 'machine_stats'

    def initialize
      Swineherd.configure_hadoop_jruby
      conf = Swineherd.get_hadoop_conf
      jconf = Java::org.apache.hadoop.mapred.JobConf.new conf

      # Using the other constructors of JobClient causes null pointer
      # exceptions, apparently due to Cloudera patches.
      @job_client = 
        Java::org.apache.hadoop.mapred.JobClient.new jconf
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
            @trackers[t] = Thread.new(t,
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

        fs = Swineherd::FileSystem.get job.get_job_file

        # There is a small chance that this will cause a
        # file-not-found exception due to a job completing between the
        # check for running status above and here. The correct
        # behavior is just to print a stack trace, because the
        # java.io.IOException that Hadoop returns can mean a lot of
        # different things: if that exception comes up, it's probably
        # something else.
        properties = JobLogParser.parse_properties(fs.open(job.get_job_file))

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
    def self.monitor_tracker hostname, coll, running_jobs
      socket = TCPSocket.open hostname, Vayacondios::DEFAULT_STAT_SERVER_PORT
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
  end
end
