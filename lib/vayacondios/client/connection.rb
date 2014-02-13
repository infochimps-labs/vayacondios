module Vayacondios::Client
  module Connection

    def self.base_uri options
      host = options[:host] || ConnectionOpts[:host]
      port = options[:port] || ConnectionOpts[:port]
      "http://#{host}:#{port}/#{Vayacondios::API_VERSION}"
    end
    
    def self.factory(options = {})
      Faraday.new(base_uri options) do |setup|
        setup.request  :json
        setup.adapter  options[:adapter] || ConnectionOpts[:adapter]
        setup.response :json, content_type: /\bjson$/
        if logger = options[:log] || ConnectionOpts[:log]
          setup.response :logger, logger
        end
      end
    end

    def organization
      'vcd'
    end

    def url(handler, topic = nil, id = nil)
      segments = [organization, handler, topic, id].compact.map(&:to_s)
      File.join(*segments)
    end

    def configure_connection options
      @connection = Connection.factory(options)
    end
    
    def http_connection
      @connection ||= Connection.factory
    end

  end
end
