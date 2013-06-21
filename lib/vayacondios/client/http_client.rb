require 'net/http'

class Vayacondios

  # A concrete implementation of a Vayacondios client which
  # communicates with the Vayacondios server over HTTP.
  #
  # Conforms to the public API of the Vayacondios::Client class.
  #
  # @see Vayacondios::Client
  # 
  # @todo Decide whether to continue to use the current
  #   no-dependencies-its-just-net-http approach or pick an HTTP
  #   client library that is non-blocking, persistent, performant,
  #   robust, &c.
  class HttpClient < Client

    # The default host for the Vayacondios server.
    HOST = 'localhost'

    # The default port for the Vayacondios server.
    PORT = 9000

    # The default headers to include with each request.
    HEADERS = {'Content-Type' => 'application/json'}

    attr_accessor :host
    attr_accessor :port
    attr_accessor :headers

    # Create a new Vayacondios::HttpClient.
    #
    # @param [Hash] options
    # @option options [String] :host ('localhost') the host of the Vayacondios server
    # @option options [Integer] :port (9000) the port of the Vayacondios server
    # @option options [Hash] :headers default headers to include with every request
    def initialize options={}
      super(options)
      self.host         = (options[:host]    || HOST).to_s
      self.port         = (options[:port]    || PORT).to_i
      self.headers      = (options[:headers] || HEADERS)
    end

    # The connection maintained to the Vayacondios server.
    #
    # @return [Net::HTTP]
    def connection
      @connection ||= Net::HTTP.new(host, port)
    end

    # Perform an HTTP request.
    #
    # Each element of `args` is turned into a segment in the path.
    # The last argument, if a Hash, is treated as the body of the
    # request.
    #
    # This method is useful for getting at various features of the
    # Vayacondios API that aren't directly exposed by the client.
    #
    # @example Retrieve an event using its ID
    #
    #   client.request(:get, 'event', 'transactions', '2387238')
    #
    # @param [String] method the HTTP method to use
    # @return [Hash,Array,String,Numeric,nil] the parsed JSON object returned by the server
    def request(method, *args)
      send_request(create_request(method, *args))
    end
    
    protected

    # Perform the actual announcement..
    # 
    # @param [String] topic
    # @param [Hash] event
    # @param [String] id
    # @return [Hash]
    #
    # @see Client#announce
    def perform_announce topic, event, id=nil
      request(:post, 'event', topic, id, body: event)
    end

    # Perform the actual search for events.
    # 
    # @param [String] topic
    # @param [Hash] query
    # @return [Array<Hash>]
    #
    # @see Client#events
    def perform_events topic, query={}
      request(:get, 'events', topic, body: query)
    end

    # Perform the actual get request.
    # 
    # @param [String] topic
    # @param [String] id
    # @return [Object]
    #
    # @see Client#get
    def perform_get topic, id=nil
      request(:get, 'stash', topic, id)
    end

    # Perform the actual search for stashes.
    # 
    # @param [Hash] query
    # @return [Array<Hash>]
    #
    # @see Client#stashes
    def perform_stashes query={}
      request(:get, 'stashes', body: query)
    end

    # Perform the actual set request.
    # 
    # @param [String] topic
    # @param [String] id
    # @param [Object] document
    # @return [Object]
    #
    # @see Client#set
    def perform_set topic, id, document
      request(:put, 'stash', topic, id, body: document)
    end
    
    # Perform the actual set! request.
    # 
    # @param [String] topic
    # @param [String] id
    # @param [Object] document
    # @return [Object]
    #
    # @see Client#set!
    def perform_set! topic, id, document
      request(:post, 'stash', topic, id, body: document)
    end

    # Perform the delete request.
    # 
    # @param [String] topic
    # @param [String] id
    # @return [Hash]
    #
    # @see Client#delete
    def perform_delete topic, id=nil
      request(:delete, 'stash', topic, id)
    end

    private

    # :nodoc:
    def create_request method, *args
      document = args.pop[:body] if args.last.is_a?(Hash)
      path    = File.join("/#{Client::VERSION}", organization, *args.compact.map(&:to_s))
      msgs    = [method.to_s.upcase, "http://#{host}:#{port}#{path}"]
      Net::HTTP.const_get(method.to_s.capitalize).new(path, headers).tap do |req|
        if document
          output   = MultiJson.dump(document)
          req.body = output
          msgs << output
        end
        log.debug(msgs.join(' '))
      end
    end

    # :nodoc:
    def send_request req
      begin
        Timeout.timeout(5) do
          handle_response(connection.request(req))
        end
      rescue Timeout::Error => e
        log.error("Timed out connecting to http://#{host}:#{port}")
        nil
      rescue Errno::ECONNREFUSED => e
        log.error("Could not connect to http://#{host}:#{port}")
        nil
      end
    end

    # :nodoc:
    def handle_response response
      case 
      when response.code.to_i == 200
        return MultiJson.load(response.body)
      when response.code.to_i == 404
        log.debug("#{response.code} -- #{response.class}")
      when response.code.to_i >= 500
        log.debug("#{response.code} -- #{response.class}")
        begin
          log.error MultiJson.load(response.body)["error"]
        rescue MultiJson::LoadError => e
          log.error(response.body)
        end
      else
        log.debug("#{response.code} -- #{response.class}")
        log.error MultiJson.load(response.body)["error"]
      end
      nil
    end
    
  end
end
