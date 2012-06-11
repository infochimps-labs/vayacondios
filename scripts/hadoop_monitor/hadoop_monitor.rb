#!/usr/bin/env jruby19

require_relative 'hadoop_client'
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
      
      @hadoop = HadoopClient.new
      
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
      loop do
        
        logger.debug "In main event loop."

        cur_running_jobs  = @hadoop.jobs_with_state HadoopClient::RUNNING
        cur_cluster_state = (cur_running_jobs.size > 0) ? CLUSTER_BUSY : CLUSTER_QUIET

        @hadoop.subtract(@monitored_jobs, cur_running_jobs).each do |job|
          logger.debug "#{job.get_id.to_s} is complete."
          update_job_stats job, Time.now
        end
        @hadoop.subtract(cur_running_jobs, @monitored_jobs).each do |job|
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

    include Configurable

    def update_cluster_state new_state
      return if new_state == @cluster_state
      @cluster_state = new_state
      logger.info "Cluster state changed to #{@cluster_state}"
      @job_events.insert(EVENT => @cluster_state, TIME => Time.now.to_i)
    end

    def update_job_properties job
      properties = @hadoop.job_properties job
      logger.debug "upserting #{JSON.generate properties}"
      @job_logs.save(properties, upsert: true, safe: true)
    end

    def update_job_stats job, finish_time = nil
      @hadoop.job_stats(job, finish_time || Time.now).each do |job_stat|
        logger.debug "upserting #{JSON.generate job_stat}"
        @job_logs.save(job_stat, upsert: true, safe: true)
      end
    end

  end
end  

Vayacondios::HadoopMonitor.new.run
