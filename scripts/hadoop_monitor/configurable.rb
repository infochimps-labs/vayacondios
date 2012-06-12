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

    declare_name :cluster_busy
    declare_name :cluster_quiet
    declare_name :event
    declare_name :time

    attr_reader :logger

    def settings
      init_settings
      return @settings
    end

    def init_settings
      return if defined? @settings
      
      @settings = Configliere::Param.new
      @settings.use :env_var, :config_file, :commandline
      
      @settings.define(:sleep_seconds,
                       default: 5,
                       description: "Time to sleep in main loops")
      @settings.define(:log_level,
                       default: "info",
                       description: "Log level. See standard Logger class")
      @settings.define(:mongo_jobs_db,
                       default: 'job_info',
                       description: "Mongo database to dump hadoop job information into")
      @settings.define(:mongo_job_logs_collection,
                       default: 'job_logs',
                       description: "Mongo collection to dump job logs into.")
      @settings.define(:mongo_job_events_collection,
                       default: 'job_events',
                       description: "Mongo collection containing jobs events.")
      @settings.define(:mongo_machine_stats_collection,
                       default: 'machine_stats',
                       description: "Mongo collection containing machine stats.")
      @settings.define(:mongo_ip,
                       default: nil,
                       description: "IP address of Hadoop monitor node")
      @settings.define(:job_logs_size,
                       default: 10 * (1 << 20),
                       description: ("Size (in bytes) of Mongo jobs log collection"))
      @settings.define(:job_events_size,
                       default: 10 * (1 << 20),
                       description: ("Size (in bytes) of Mongo job events collection"))
      @settings.define(:machine_stats_size,
                       default: 100 * (1 << 20),
                       description: ("Size (in bytes) of machine stats collection"))
      
      @settings.resolve!

      @logger = Logger.new(STDERR)
      @logger.level = Logger.const_get(@settings.log_level.upcase.to_sym)

      @logger.info "Settings: #{@settings}"

      @settings
    end
  end
end
