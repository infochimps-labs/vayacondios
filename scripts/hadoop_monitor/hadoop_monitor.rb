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
      @conn = Mongo::Connection.new settings.mongo_ip
      @db = @conn[settings.mongo_jobs_db]
      @job_logs = @db.create_collection(settings.mongo_job_logs_collection)

      # After we create the job_events database, one of the machine
      # monitors will create the machine stats databse.
      @job_events = @db.create_collection(settings.mongo_job_events_collection,
                                          :capped => true,
                                          :size => settings.job_events_size)

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

        sleep settings.sleep_seconds

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
      @job_logs.update(_id: properties[:_id], properties, upsert: true, safe: true)
    end

    def update_job_stats job, finish_time = nil
      @hadoop.job_stats(job, finish_time || Time.now).each do |job_stat|
        logger.debug "upserting #{JSON.generate job_stat}"
        @job_logs.update(_id: job_stat[:_id], job_stat, upsert: true, safe: true)
      end
    end

  end
end

Vayacondios::HadoopMonitor.new.run
