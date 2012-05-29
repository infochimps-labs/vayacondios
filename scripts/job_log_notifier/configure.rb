require 'configliere'

module Vayacondios

  module Configurable

    #
    # Declare a name CONST_NAME = :const_name
    #
    def self.declare_name symbol
      const_set symbol.to_s.upcase.to_sym, symbol
    end

    declare_name :stat_server_port
    declare_name :sleep_seconds
    declare_name :mongo_jobs_db
    declare_name :mongo_job_logs_collection
    declare_name :mongo_job_events_collection
    declare_name :mongo_machine_stats_collection
    declare_name :job_logs_size
    declare_name :job_events_size
    declare_name :machine_stats_size
    declare_name :cluster_working
    declare_name :cluster_quiet
    declare_name :event
    declare_name :time
    declare_name :hadoop_monitor_node

    def get_conf
      return @conf if defined? @conf

      @conf = Configliere::Param.new
      @conf.use :env_var, :config_file, :commandline, :config_block
      
      @conf \
      STAT_SERVER_PORT => 13622,
      SLEEP_SECONDS => 1,
      MONGO_JOBS_DB => 'job_info',
      MONGO_JOB_LOGS_COLLECTION => 'job_logs',
      MONGO_JOB_EVENTS_COLLECTION => 'job_events',
      MONGO_MACHINE_STATS_COLLECTION => 'machine_stats',
      HADOOP_MONITOR_NODE => nil,
      JOB_LOGS_SIZE => 10 * (1 << 20),
      JOB_EVENTS_SIZE => 10 * (1 << 20),
      MACHINE_STATS_SIZE => 100 * (1 << 20)

      # unconfigurable constants
      @conf.finally do |cnf|
        cnf[CLUSTER_WORKING] = "cluster_working"
        cnf[CLUSTER_QUIET] = "cluster_quiet"
        cnf[EVENT] = "event"
        cnf[TIME] = "time"
      end

      @conf.resolve!
      @conf
    end
  end

  class Configuration
    include Configurable
  end
end
