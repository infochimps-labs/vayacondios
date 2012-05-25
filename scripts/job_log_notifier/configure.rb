require 'configliere'

module Vayacondios

  module Configurable
    STAT_SERVER_PORT = :stat_server_port
    SLEEP_SECONDS = :sleep_seconds
    MONGO_JOBS_DB = :mongo_jobs_db
    MONGO_JOB_LOGS_COLLECTION = :mongo_job_logs_collection
    MONGO_JOB_EVENTS_COLLECTION = :mongo_job_events_collection
    MONGO_MACHINE_STATS_COLLECTION = :mongo_machine_stats_collection
    JOB_LOGS_SIZE = :job_logs_size
    JOB_EVENTS_SIZE = :job_events_size
    MACHINE_STATS_SIZE = :machine_stats_size

    # unconfigurable constants
    CLUSTER_WORKING = "cluster_working"
    CLUSTER_QUIET = "cluster_quiet"
    EVENT = "event"
    TIME = "time"

    def conf
      @conf ||= Configliere::Param.new\
      STAT_SERVER_PORT => 13622,
      SLEEP_SECONDS => 1,
      MONGO_JOBS_DB => 'job_info',
      MONGO_JOB_LOGS_COLLECTION => 'job_logs',
      MONGO_JOB_EVENTS_COLLECTION => 'job_events',
      MONGO_MACHINE_STATS_COLLECTION => 'machine_stats',
      JOB_LOGS_SIZE => 10 * (1 << 20),
      JOB_EVENTS_SIZE => 10 * (1 << 20),
      MACHINE_STATS_SIZE => 100 * (1 << 20),
    end
  end

  class Configuration
    include Configurable
  end
end
