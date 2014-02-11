module Vayacondios::Server
  module Driver

    Error = Class.new(StandardError) unless defined? Error

    # Factory methods for drivers
    class << self
      def drivers
        @list ||= {
          mongo: MongoDriver,
        }
      end

      def load_driver handle
        drivers = File.expand_path('../drivers', __FILE__)
        driver_file = File.join(drivers, handle.to_s + '.rb')
        load driver_file if File.exist? driver_file
      end

      def retrieve handle
        load_driver handle
        drivers[handle.to_sym]
      end

      def included base
        base.class_eval{ attr_reader :location, :log } if base.is_a? Class
      end
    end

    # Main api entrance method
    def call(name, request, *options)
      send("base_#{name}", request)
      set_location request.location
      send(name, request.document, *options)
    end

    def base_insert request
      log.debug "  Processing by #{self.class}#insert"
    end

    def base_retrieve request
      log.debug "  Processing by #{self.class}#retrieve"
    end

    def base_update request
      log.debug "  Processing by #{self.class}#update"
    end

    def base_search request
      log.debug "  Processing by #{self.class}#search"
    end

    def base_remove request
      log.debug "  Processing by #{self.class}#remove"
    end

    def set_location loc
      log.debug "    Location: #{loc}"
      @location = loc
    end

    def set_log device
      @log = device
    end
  end
end
