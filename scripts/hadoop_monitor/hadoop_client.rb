require_relative 'configurable'
require_relative 'hadoopable'
require 'json'
require 'optparse'
require 'ostruct'
require 'logger'
require 'pp'
require 'gorillib/string/inflections'
require 'swineherd-fs'

module Vayacondios

  class HadoopClient

    include Configurable
    include Hadoopable

    RUNNING = JobStatus::RUNNING

    def initialize
      init_settings
      logger.info "Connecting to job tracker."
      @job_client = JobClient.new JobConf.new(get_hadoop_conf)
    end

    #
    # (Equality doesn't work for jobs, so - will not work as intended
    # on arrays of jobs.)
    #
    def subtract jobs_array1, jobs_array2
      jobs_array1.reject{|j| jobs_array2.map(&:job_id).map(&:to_s).index j.job_id.to_s}
    end

    #
    # Returns the jobs with the specified state. States are specified
    # by constants in this class.
    #
    def jobs_with_state state
      jobs_by_state[state] || []
    end

    #
    # Returns the properties of the specified job as a hash.
    #
    def job_properties job
      host_port = job.get_tracking_url[/^(http:\/\/)?[^\/]*/]
      job_id = job.get_id.to_s
      conf_uri = "#{host_port}/logs/#{job_id}_conf.xml"
      properties = parse_properties(open conf_uri)
      recordize_properties(properties, job_id.to_s)
    end

    #
    # Returns the stats for the current job as a hash.
    #
    def job_stats job, finish_time
      parse_job job.get_id.to_s, finish_time
    end

  private

    #
    # Returns a hash JobStatus::<SOME_STATE> => <array of jobs>
    #
    def jobs_by_state
      job_statuses_by_state = @job_client.get_all_jobs.group_by(&:get_run_state)
      Hash[job_statuses_by_state.map{|state, job_statuses| [state, jobs_from_statuses(job_statuses)]}]
    end

    #
    # Some hadoop stuff returns JobStatus objects. This converts them
    # to RunningJob objects.
    #
    def jobs_from_statuses job_statuses
      job_statuses.map{|job_status| @job_client.get_job job_status.get_job_id}
    end

    #
    # Takes an org.apache.hadoop.mapred.RunningJob and returns a hash
    # object that represents it.
    #
    def parse_job job_id, finish_time
      job = @job_client.get_job job_id
      job_status = job.get_job_status
      finished_status = [:FAILED, :KILLED, :COMPLETE]
      failed_status   = [:FAILED]

      start_time      = Time.at(job_status.get_start_time / 1000)
      reduce_progress = job.reduce_progress
      run_duration    = finish_time - start_time

      job_data = {

        _id:              job_id.to_s,
        name:             get_job_name.to_s,

                          # not sure what is what. I'm guessing
                          # JobStatus.getStartTime corresponds to the
                          # launch time in the logs, but I'm going to
                          # go ahead and use it twice here.

        launch_time:      start_time,
        submit_time:      start_time,
        finish_time:      finish_time,

        run_duration:     run_duration,
        eta:              reduce_progress && reduce_progress > 0.0 ? (start_time + (run_duration / reduce_progress)) : nil

        job_status:       case job_status.get_run_state
                          when JobStatus::FAILED    then :FAILED
                          when JobStatus::KILLED    then :KILLED
                          when JobStatus::PREP      then :PREP
                          when JobStatus::RUNNING   then :RUNNING
                          when JobStatus::SUCCEEDED then :SUCCEEDED
                          end,

        finished_maps:    num_tasks(job_id, :map,    finished_status),
        finished_reduces: num_tasks(job_id, :reduce, finished_status),
        failed_maps:      num_tasks(job_id, :map,    failed_status),
        failed_reduces:   num_tasks(job_id, :reduce, failed_status),

        counters:         parse_counters(job.get_counters),
        type:             :job,

      }

      job_progress = {

        parent_id:        job.job_id,
        type:             :job_progress,
                          # report time in milliseconds for consistency
        time:             Time.now,
        cleanup_progress: job.cleanup_progress,
        map_progress:     job.map_progress,
        reduce_progress:  job.reduce_progress,
        setup_progress:   job.setup_progress,

      }

      map_task_data    = @job_client.get_map_task_reports    job_id
      reduce_task_data = @job_client.get_reduce_task_reports job_id

      m_reports, m_progress_reports, r_reports, r_progress_reports =
        [
         map_task_data   .map{|task| parse_task          task, "MAP",    job_id },
         map_task_data   .map{|task| parse_task_progress task, "MAP"            },
         reduce_task_data.map{|task| parse_task          task, "REDUCE", job_id },
         reduce_task_data.map{|task| parse_task_progress task, "REDUCE"         },
        ]

      [job_data, job_progress] + m_reports + r_reports + m_progress_reports + r_progress_reports
    end

    def recordize_properties properties, job_id
      {
        parent_id:  job_id,
        type:       :conf,
        properties: properties,
        _id:        [job_id, "_properties"].join
      }
    end

    #
    # Return a hash containing a name => value hash representing the
    # config for a hadoop job.
    #
    def parse_properties conf
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
    # Takes an org.apache.hadoop.mapred.TaskReport and returns a Hash
    # object that represents it.
    #
    def parse_task task_report, task_type, parent_job_id
      {
        _id:                task_report.get_task_id.to_s,
        parent_id:          parent_job_id,
        task_type:          task_type,
        task_status:        task_report.get_current_status.to_s,
        start_time:         Time.at(task_report.get_start_time / 1000),
        finish_time:        Time.at(task_report.get_finish_time / 1000),
        counters:           parse_counters(task_report.get_counters),
        type:               :task,
        diagnostics:        task_report.get_diagnostics.map(&:to_s),
        successful_attempt: task_report.get_successful_task_attempt.to_s,
        '$addToSet' => {
          attempts: {
            '$each' => task_report.get_running_task_attempts.map(&:to_s)
          }
        }
      }
    end

    def parse_task_progress task_report, task_type
      {
        parent_id:          task_report.get_task_id.to_s,
        time:               Time.now,
        type:               :task_progress,
        progress:           task_report.get_progress,
        running_attempts:   task_report.get_running_task_attempts.map(&:to_s)
      }
    end

    #
    # Takes a class of type org.apache.hadoop.mapred.Counters and
    # returns a Hash object that represents this counter.
    #
    def parse_counters counters
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
    def parse_key key
      return (parse_atom key).underscore.gsub ".", "_"
    end

    #
    # Parse a value in a Hadoop log.
    #
    def parse_atom a
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
    # Returns the number of tasks of the specified TIPStatus from the
    # specified job_client of the specified type (map or reduce)
    #
    def num_tasks job_id, map_or_reduce, statuses
      method_name = "get_#{map_or_reduce}_task_reports".to_sym
      @job_client.send(method_name, job_id).select do |report|
        tip_statuses = statuses.map do |status|
          TIPStatus.const_get status
        end
        tip_statuses.index report.get_current_status
      end.size
    end
  end
end
