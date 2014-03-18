module Vayacondios::Client
  module HttpRead
    include Connection

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

 # Stream events
    # only when in an eventmachine reactor
    def evented_stream(topic, query = {}, &on_event)
      uri = http_connection.url_prefix
      uri.path = File.join(uri.request_uri, url('stream', topic))
      http = EM::HttpRequest.new(uri, query: query.merge(order: 'asc')).aget
      buffer = ''
      http.stream do |chunk|
        puts "got chunk #{chunk}"
        buffer += chunk
        while line = buffer.slice!(/^[^\n].*\n/)
          on_event.call MultiJson.load(line.strip)
        end
      end
    end

    # Stream events
    # only works with net/http
    def stream(topic, query = {}, &on_event)
      uri = http_connection.url_prefix
      Net::HTTP.start(uri.host, uri.port) do |http|
        path = File.join(uri.request_uri, url('stream', topic))
        request = Net::HTTP::Get.new(path)
        http.request(request) do |response|
          buffer = ''
          response.read_body do |chunk|
            buffer += chunk
            while line = buffer.slice!(/^[^\n].*\n/)
              on_event.call MultiJson.load(line.strip)
            end
          end
        end
      end
    end
  end

  module HttpWrite
    include Connection

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

  module HttpAdmin
    include Connection

    # Delete one stash
    def unset(topic, id = nil)
      http_connection.delete url('stash', topic, id)
    end

    # Delete stashes by search
    def unset_many(query = {})
      http_connection.delete url('stashes') do |req|
        req.body = query
      end
    end

    # Delete all events by topic and query
    def clear_events(topic, query = {})
      http_connection.delete url('events', topic) do |req|
        req.body = query
      end
    end
  end
end
