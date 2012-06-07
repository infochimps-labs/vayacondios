#!/usr/bin/env jruby19

require_relative 'job_log_parser'
require_relative 'configurable'
require 'java'
require 'mongo'
require 'scanf'
require 'gorillib/hash/slice'
require 'thread'
require 'open-uri'
require 'json'

module Vayacondios

  class HadoopMonitor
    def initialize
      init_settings
      
      self.configure_hadoop_jruby
      
      @monitored_jobs = []

      logger.debug "Creating mongo collections."
      @conn = Mongo::Connection.new settings[MONGO_IP]
      @db = @conn[settings[MONGO_JOBS_DB]]
      @job_logs = @db.create_collection(settings[MONGO_JOB_LOGS_COLLECTION])

      # After we create the job_events database, one of the machine
      # monitors will create the machine stats databse.
      @job_events = @db.create_collection(settings[MONGO_JOB_EVENTS_COLLECTION],
                                          :capped => true,
                                          :size => settings[JOB_EVENTS_SIZE])

      @cluster_state = CLUSTER_QUIET
    end

    def run
      logger.info "Connecting to job tracker."
      @job_client = JobClient.new Java::org.apache.hadoop.mapred.JobConf.new(self.get_hadoop_conf)

      loop do
        
        logger.debug "In main event loop."

        cur_running_jobs   = jobs_with_state JobStatus::RUNNING
        cur_cluster_state  = current_cluster_state cur_running_jobs

        subtract(@monitored_jobs, cur_running_jobs).each{|job| logger.debug "#{job.get_id.to_s} is complete."}
        subtract(cur_running_jobs, @monitored_jobs).each do |job|
          logger.debug "#{job.get_id.to_s} started."
          update_job_properties job
        end

        (@monitored_jobs + cur_running_jobs).each{|job| update_job_stats job}

        @monitored_jobs = cur_running_jobs
        update_cluster_state cur_cluster_state

        sleep settings[SLEEP_SECONDS]

      end
    end

  private

    include JobLogParser
    include Configurable

    #
    # Get the current state of the cluster
    #
    def current_cluster_state cur_running_jobs
      case cur_running_jobs.size > 0
      when true then CLUSTER_BUSY
      when false then CLUSTER_QUIET
      end
    end

    #
    # (Equality doesn't work for jobs, so - will not work as intended
    # on arrays of jobs.)
    #
    def subtract jobs_array1, jobs_array2
      jobs_array1.reject{|j| jobs_array2.map(&:job_id).map(&:to_s).index j.job_id.to_s}
    end

    def jobs_with_state state
      jobs_by_state[state] || []
    end

    def update_cluster_state new_state
      return if new_state == @cluster_state
      @cluster_state = new_state
      logger.info "Cluster state changed to #{@cluster_state}"
      @job_events.insert(EVENT => @cluster_state, TIME => Time.now.to_i)
    end

    def jobs_from_statuses job_statuses
      job_statuses.map{|job_status| @job_client.get_job job_status.get_job_id}
    end

    def jobs_by_state
      job_statuses_by_state = @job_client.get_all_jobs.group_by(&:get_run_state)
      Hash[job_statuses_by_state.map{|state, job_statuses| [state, jobs_from_statuses(job_statuses)]}]
    end

    #
    # Updates the properties of the specified job.
    #
    def update_job_properties job
      host_port = job.get_tracking_url[/^(http:\/\/)?[^\/]*/]
      job_id = job.get_id.to_s
      conf_uri = "#{host_port}/logs/#{job_id}_conf.xml"
      properties = JobLogParser.parse_properties(open conf_uri)
      prop_record = JobLogParser.recordize_properties(properties, job_id.to_s)
      logger.debug "upserting #{JSON.generate prop_record}"
      @job_logs.update({_id: [job_id.to_s, '_properties'].join}, prop_record, upsert: true, safe: true)
    end

    #
    # Updates the stats for the specified job.
    #
    def update_job_stats job
      job_id = job.get_id.to_s
      job_stats = JobLogParser.parse_job @job_client, job_id, nil
      job_stats.each do |job_stat|
        logger.debug "upserting #{JSON.generate job_stat}"
        @job_logs.update({_id: job_stat[:_id]}, job_stat, upsert: true, safe: true)
      end
    end
    
  end
end  

Vayacondios::HadoopMonitor.new.run
