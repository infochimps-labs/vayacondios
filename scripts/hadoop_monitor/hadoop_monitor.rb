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
      @db = @conn[settings.mongo_db]

      capped_collection_opts = {
        :capped => true,
        :size => settings.mongo_collection_size
      }

      @collections = {
        jobs:     @db.create_collection('jobs'),
        tasks:    @db.create_collection('job_tasks'),
        attempts: @db.create_collection('job_task_attempts'),

        job_events:     @db.create_collection('job_events',      capped_collection_opts),
        task_events:    @db.create_collection('job_task_events', capped_collection_opts),
      }
    end

    def run
      loop do

        logger.debug "In main event loop."

        running_jobs  = @hadoop.jobs_with_state HadoopClient::RUNNING
        started_jobs  = @hadoop.subtract(running_jobs, @monitored_jobs)
        finished_jobs = @hadoop.subtract(@monitored_jobs, running_jobs)

        finished_jobs.each do |job|
          logger.debug "#{job.get_id.to_s} is complete."
          update_job_stats job, Time.now
        end

        running_jobs.each{|job| update_job_stats job, nil, @hadoop.subtract([job], started_jobs).empty? }

        @monitored_jobs = running_jobs

        sleep settings.sleep_seconds

      end
    end

  private

    include Configurable

    def update_job_stats job, finish_time = nil, include_properties = false
      stats = @hadoop.job_stats(job, finish_time)

      if include_properties
        stats[:job][:properties] = @hadoop.job_properties job
      end

      logger.debug "upserting job #{JSON.generate stats[:job]}"
      @collections[:jobs].update({_id: stats[:job][:_id]}, stats[:job], upsert: true)

      logger.debug "upserting job_event #{JSON.generate stats[:job_event]}"
      @collections[:job_events].insert(stats[:job_event])

      logger.debug "upserting tasks #{JSON.generate stats[:tasks]}"
      stats[:tasks].each do |task|
        @collections[:tasks].update({_id: task[:_id]}, task, upsert: true)
      end

      logger.debug "upserting task_events #{JSON.generate stats[:task_events]}"
      stats[:task_events].each do |task_event|
        @collections[:task_events].insert(task_event)
      end

      logger.debug "upserting attempts #{JSON.generate stats[:attempts]}"
      stats[:attempts].each do |attempt|
        @collections[:attempts].update({_id: attempt[:_id]}, attempt, upsert: true)
      end
    end

  end
end

Vayacondios::HadoopMonitor.new.run
