require 'configliere'
require 'logger'

class Vayacondios

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

      @settings.define(:config_file,
                       description: "Config file location")
      @settings.define(:sleep_seconds,
                       default: 5,
                       description: "Time to sleep in main loops")
      @settings.define(:log_level,
                       default: "info",
                       description: "Log level. See standard Logger class")
      @settings.define(:mongo_db,
                       default: 'job_info',
                       description: "Mongo database to dump hadoop job information into")
      @settings.define(:mongo_ip,
                       default: nil,
                       description: "IP address of Hadoop monitor node")
      @settings.define(:mongo_collection_size,
                       default: 10 * (1 << 20),
                       description: ("Size (in bytes) of Mongo job events collection"))

      @settings.resolve!

      if @settings.config_file
        @settings.read(@settings.config_file)
        @settings.resolve!
      end

      @logger = Logger.new(STDERR)
      @logger.level = Logger.const_get(@settings.log_level.upcase.to_sym)

      @logger.info "Settings: #{@settings}"

      @settings
    end
  end
end
