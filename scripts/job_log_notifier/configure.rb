require 'configliere'

module Vayacondios

  module Configurable
    STAT_SERVER_PORT = :stat_server_port
    IFSTAT_READ_BUF_SIZE = :ifstat_read_buf_size
    SLEEP_SECONDS = :sleep_seconds
    MONGO_JOBS_DB = :mongo_jobs_db
    MONGO_JOB_LOGS_COLLECTION = :mongo_job_logs_collection
    MONGO_JOB_EVENTS_COLLECTION = :mongo_job_events_collection
    MONGO_MACHINE_STATS_COLLECTION = :mongo_machine_stats_collection

    def conf
      @conf ||= Configliere::Param.new\
      STAT_SERVER_PORT => 13622,
      IFSTAT_READ_BUF_SIZE => 0x10000,
      SLEEP_SECONDS => 1,
      MONGO_JOBS_DB => 'job_info',
      MONGO_JOB_LOGS_COLLECTION => 'job_logs',
      MONGO_JOB_EVENTS_COLLECTION => 'job_events',
      MONGO_MACHINE_STATS_COLLECTION => 'machine_stats'
    end
  end

  class Configuration
    include Configurable
  end
end
