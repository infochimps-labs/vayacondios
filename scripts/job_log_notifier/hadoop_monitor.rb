#!/usr/bin/env jruby

require_relative 'job_log_parser'
require 'swineherd-fs'
require 'java'
require 'mongo'

module Vayacondios

  class HadoopMonitor

    include JobLogParser

    SLEEP_SECONDS = 1
    MONGO_JOBS_DB = 'job_info'
    MONGO_JOB_LOGS_COLLECTION = 'job_logs'

    def initialize
      Swineherd.configure_hadoop_jruby
      conf = Swineherd.get_hadoop_conf
      jconf = Java::org.apache.hadoop.mapred.JobConf.new conf

      # Using the other constructors of JobClient causes null pointer
      # exceptions, apparently due to Cloudera patches.
      @job_client = 
        Java::org.apache.hadoop.mapred.JobClient.new jconf
      @launched_jobs = {}
      @conn = Mongo::Connection.new
      @db = @conn[MONGO_JOBS_DB]
      @coll = @db[MONGO_JOB_LOGS_COLLECTION]
    end

    def run
      include_class [org.apache.hadoop.mapred.JobProfile,
                     java.io.DataOutputStream,
                     java.io.ByteArrayOutputStream]

      while true
        sleep SLEEP_SECONDS

        @job_client.get_all_jobs.select do |job_status|
          job_status.get_run_state ==
            Java::org.apache.hadoop.mapred.JobStatus::RUNNING
        end.each do |job_status|
          job = @job_client.get_job job_status.get_job_id

          unless @launched_jobs[job.get_id.to_s]
            @launched_jobs[job.get_id.to_s] = job
            
            Thread.new(job, @coll) do |job, coll|
              self.class.watch_job_events job, coll
            end
            
          end
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
    def self.watch_job_events job, coll
      begin
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
      end
    end
  end
end
