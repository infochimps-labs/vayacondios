#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'ostruct'
require 'logger'
require 'pp'
require 'gorillib/hash/compact'
require 'gorillib/string/inflections'
require 'swineherd-fs'

module Vayacondios

  module JobLogParser

  public
    
    def self.recordize_properties properties, job_id
      {
        parent: job_id,
        type: 'conf',
        properties: properties,
        _id: [job_id, "_properties"].join
      }
    end

    #
    # Return a hash containing a name => value hash representing the
    # config for a hadoop job.
    #
    def self.parse_properties conf
      properties = {}
      conf.read.scan /[^\n]*\n/ do |line,|
        m = /<name>([^<]+)<\/name><value>([^<]+)<\/value>/.match line
        if m and m[1] !~ /fs\.s3n?\.awsSecretAccessKey/ then
          properties[parse_key m[1]] = parse_atom m[2]
        end
      end
      properties
    end

    #
    # Takes an org.apache.hadoop.mapred.RunningJob and returns a hash
    # object that represents it.
    #
    def self.parse_job job_client, job_id, finish_time
      job = job_client.get_job job_id
      job_status = job_client.get_all_jobs.select{|j| j.get_job_id.to_s == job_id.to_s}.first

      include_class org.apache.hadoop.mapred.JobStatus

      finished_status = [:FAILED, :KILLED, :COMPLETE]
      failed_status = [:FAILED]

      job_data = {
        
        # missing some fields that show up in the logs here, but this
        # should be a subset of the values provided there
        
        _id:              job_id.to_s,

                          # not sure what is what. I'm guessing
                          # JobStatus.getStartTime corresponds to the
                          # launch time in the logs, but I'm going to
                          # go ahead and use it twice here.

        launch_time:      job_status.get_start_time,
        submit_time:      job_status.get_start_time,

        job_status:       case job_status.get_run_state
                          when JobStatus::FAILED    then :FAILED 
                          when JobStatus::KILLED    then :KILLED
                          when JobStatus::PREP      then :PREP
                          when JobStatus::RUNNING   then :RUNNING
                          when JobStatus::SUCCEEDED then :SUCCEEDED
                          end,

        finished_maps:    num_tasks(job_client, job_id, :map, finished_status),
        finished_reduces: num_tasks(job_client, job_id, :reduce, finished_status),
        failed_maps:      num_tasks(job_client, job_id, :map, failed_status),
        failed_reduces:   num_tasks(job_client, job_id, :reduce, failed_status),
        counters:         parse_counters(job.get_counters),
        type:             :job,

      }

      job_data[:finish_time] = finish_time if finish_time

      map_task_data    = job_client.get_map_task_reports    job_id
      reduce_task_data = job_client.get_reduce_task_reports job_id
      
      map_reports    =    map_task_data.map{|task| parse_task task, "MAP",    job_id }
      reduce_reports = reduce_task_data.map{|task| parse_task task, "REDUCE", job_id }

      [job_data] + map_reports + reduce_reports
    end

  private
    
    #
    # Takes an org.apache.hadoop.mapred.TaskReport and returns a Hash
    # object that represents it.
    #
    def self.parse_task task_report, task_type, parent_job_id
      {
        _id:         task_report.getTaskID.to_s,
        parent_id:   parent_job_id,
        task_type:   task_type,
        task_status: task_report.get_current_status.to_s,
        start_time:  task_report.get_start_time,
        finish_time: task_report.get_finish_time,
        counters:    parse_counters(task_report.get_counters),
        type:        :task,
      }
    end

    #
    # Returns the number of tasks of the specified TIPStatus from the
    # specified job_client of the specified type (map or reduce)
    #
    def self.num_tasks job_client, job_id, map_or_reduce, statuses
      method_name = "get_#{map_or_reduce}_task_reports".to_sym
      job_client.send(method_name, job_id).select do |report|
        tip_statuses = statuses.map do |status|
          Java::org.apache.hadoop.mapred.TIPStatus.const_get status
        end
        tip_statuses.index report.get_current_status
      end.size
    end

    #
    # Takes a class of type org.apache.hadoop.mapred.Counters and
    # returns a Hash object that represents this counter.
    #
    def self.parse_counters counters
      Hash[counters.map do |group|
             [parse_key(group.get_name), Hash[group.map do |counter|
                                                [parse_key(counter.get_name), counter.get_counter]
                                              end]]
           end]
    end

    #
    # Parse a key in a log entry. Log entries consist of a type, which I
    # consider a key, and a list of key=value pairs.
    #
    def self.parse_key key
      return (parse_atom key).underscore.gsub ".", "_"
    end

    #
    # Parse a value in a Hadoop log.
    #
    def self.parse_atom a
      if /[0-9][ \r\t\n]*\/[ \r\t\n]*[0-9]+/.match a
        # "0/6" -> [0,6]
        return a.split("/").collect{|s| s.to_i}
      elsif /^[0-9,]*$/.match a
        # "224" -> 224
        return a.gsub(',', '').to_i
      else
        # \. -> .
        return a.gsub(/([^\\])\\(.)/, '\1\2')
      end
    end

    #
    # returns a regex that matches until character b. Escaped b's are
    # skipped over.
    #
    def self.scan_until b
      return /(?:[^\\#{b}]|\\.)*/
    end

    #
    # parses counters in a Hadoop log into a hash
    #
    def self.parse_log_counters counters
      result = {}
      counters.scan /{(#{scan_until '\['})(#{scan_until "\}"})}/ do |counter|
        headers, table = counter
        headers.scan(/\((#{scan_until ')'})\)
                  \((#{scan_until ')'})\)/x) do |type, description|
          type = parse_key type
          result[type] = {}
          table.scan(/\[\((#{scan_until ')'})\)
                    \((#{scan_until ')'})\)
                    \((#{scan_until ')'})\)\]/x) do |name,description,val|
            result[type][parse_key name] = parse_atom val
          end
        end
      end
      return result
    end

  end
end
