class Vayacondios
  module Server
    module Driver

      def self.drivers
        @list ||= {
          mongo: MongoDriver,
        }
      end

      def self.load_driver handle
        drivers = File.expand_path('../drivers', __FILE__)
        driver_file = File.join(drivers, handle.to_s + '.rb')
        load driver_file if File.exist? driver_file
      end
      
      def self.retrieve handle
        load_driver handle
        drivers[handle.to_sym]
      end

      def self.names
        drivers.keys
      end

    end
  end
end
