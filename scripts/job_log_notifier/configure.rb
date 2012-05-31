require 'configliere'
require 'logger'

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
    declare_name :monitoring_cluster
    declare_name :cluster_working
    declare_name :cluster_quiet
    declare_name :event
    declare_name :time
    declare_name :mongo_ip
    declare_name :log_level

    attr_reader :logger

    def get_conf
      return @conf if defined? @conf

      @conf = Configliere::Param.new
      @conf.use :env_var, :config_file, :commandline, :config_block
      
      @conf.define(SLEEP_SECONDS,
                   :default => 1,
                   :description => "Time to sleep in main loops")
      @conf.define(LOG_LEVEL,
                   :default => "info",
                   :description => "Log level. See standard Logger class")
      @conf.define(MONGO_JOBS_DB,
                   :default => 'job_info',
                   :description => "Mongo database to dump hadoop job information into")
      @conf.define(MONGO_JOB_LOGS_COLLECTION,
                   :default => 'job_logs',
                   :description => "Mongo collection to dump job logs into.")
      @conf.define(MONGO_JOB_EVENTS_COLLECTION,
                   :default => 'job_events',
                   :description => "Mongo collection containing jobs events.")
      @conf.define(MONGO_MACHINE_STATS_COLLECTION,
                   :default => 'machine_stats',
                   :description => "Mongo collection containing machine stats.")
      @conf.define(MONGO_IP,
                   :default => nil,
                   :description => "IP address of Hadoop monitor node")
      @conf.define(JOB_LOGS_SIZE,
                   :default => 10 * (1 << 20),
                   :description => ("Size (in bytes) of Mongo jobs log " \
                                    "collection"))
      @conf.define(JOB_EVENTS_SIZE,
                   :default => 10 * (1 << 20),
                   :description => ("Size (in bytes) of Mongo job events " \
                                    "collection"))
      @conf.define(MACHINE_STATS_SIZE,
                   :default => 100 * (1 << 20),
                   :description => ("Size (in bytes) of machine stats " \
                                    "collection"))

      # unconfigurable constants
      @conf.finally do |cnf|
        cnf[CLUSTER_WORKING] = "cluster_working"
        cnf[CLUSTER_QUIET] = "cluster_quiet"
        cnf[MONITORING_CLUSTER] = "monitoring_cluster"
        cnf[EVENT] = "event"
        cnf[TIME] = "time"
      end

      @conf.resolve!

      @logger = Logger.new(STDERR)
      @logger.level = Logger.const_get(@conf[LOG_LEVEL].upcase.to_sym)

      @conf
    end
  end

  class Configuration
    include Configurable
  end
end
