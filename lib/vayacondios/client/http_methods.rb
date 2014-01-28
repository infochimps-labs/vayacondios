module Vayacondios
  module HttpMethods

    def self.included base
      base.class_eval{ class_attribute :organization }
    end

    # This only actually applies when using this mixin with a model
    # def type
    #   self.class.to_s.demodulize.underscore
    # end

    def base_uri
      "http://#{Vayacondios::ConnectionOpts[:host]}:#{Vayacondios::ConnectionOpts[:port]}/v2"
    end
    
    def http_connection
      @http_connection ||= Faraday.new(base_uri) do |setup|
        setup.request  :json
        setup.response :json, content_type: /\bjson$/
        setup.response :logger, Vayacondios::ConnectionOpts[:log]
        setup.adapter  Vayacondios::ConnectionOpts[:adapter]
      end
    end

    def url(handler, topic = nil, id = nil)
      File.join(*[organization.to_s, handler, topic, id].compact)
    end

    def get(topic, id = nil)
      http_connection.get url('stash', topic, id)
    end

    def get_many(query = {})
      http_connection.get url('stashes') do |req|
        req.body = query
      end
    end

    def set(topic, id = nil, stash = {})
      http_connection.post url('stash', topic, id) do |req|
        req.body = stash
      end
    end
    alias :set! :set

    def unset topic
      http_connection.delete url('stash', topic)
    end

    def unset_many(query = {})
      http_connection.delete url('stashes') do |req|
        req.body = query
      end
    end

    def announce(topic, event = {}, id = nil)
      http_connection.post url('event', topic, id) do |req|
        req.body = event
      end
    end

    def events(topic, query = {})
      http_connection.get url('events', topic) do |req|
        req.body = query
      end
    end
  end
end
