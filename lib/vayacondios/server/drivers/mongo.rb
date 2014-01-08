class Vayacondios
  module Server
    class MongoDriver

      attr_reader :connection

      def self.connect(options = {})
        new(options).connection
      end

      def initialize(options = {})
        mongo = EM::Mongo::Connection.new(options[:host], options[:port], 1, reconnect_in: 1)
        @connection = mongo.db(options[:name])
      end
      
    end
  end
end
