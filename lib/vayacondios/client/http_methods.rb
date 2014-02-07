module Vayacondios
  module BaseHttp

    def url(handler, topic = nil, id = nil)
      # Must respond to organization for this to work
      File.join(*[organization.to_s, handler, topic, id].compact)
    end
    
    def http_connection
      @connection ||= Vayacondios::Client.new_connection
    end

  end

  module HttpReadMethods
    include BaseHttp

    # Retrieve one stash
    def get(topic, id = nil)
      http_connection.get url('stash', topic, id)
    end

    # Search stashes
    def get_many(query = {})
      http_connection.get url('stashes') do |req|
        req.body = query
      end
    end

    # Search events
    def events(topic, query = {})
      http_connection.get url('events', topic) do |req|
        req.body = query
      end
    end
  end

  module HttpWriteMethods
    include BaseHttp

    # Create a stash
    def set(topic, id = nil, stash = {})
      http_connection.post url('stash', topic, id) do |req|
        req.body = stash
      end
    end
    alias :set! :set

    # Create an event
    def announce(topic, event = {}, id = nil)
      http_connection.post url('event', topic, id) do |req|
        req.body = event
      end
    end
  end

  module HttpAdminMethods
    include BaseHttp

    # Delete one stash
    def unset topic
      http_connection.delete url('stash', topic)
    end

    # Delete stashes by search
    def unset_many(query = {})
      http_connection.delete url('stashes') do |req|
        req.body = query
      end
    end
  end
end
