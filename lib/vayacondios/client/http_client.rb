require 'net/http'

class Vayacondios
  class HttpClient < Client

    HOST    = 'localhost'
    PORT    = 9000
    HEADERS = {'Content-Type' => 'application/json'}

    attr_accessor :host
    attr_accessor :port
    attr_accessor :headers

    def initialize options={}
      super(options)
      self.host         = (options[:host]    || HOST).to_s
      self.port         = (options[:port]    || PORT).to_i
      self.headers      = (options[:headers] || HEADERS)
    end

    def connection
      @connection ||= Net::HTTP.new(host, port)
    end

    protected
    
    def perform_announce topic, event, id=nil
      request(:post, 'event', topic, id, body: event)
    end

    def perform_get topic, id=nil
      request(:get, 'stash', topic, id)
    end

    def perform_set topic, id, document
      request(:put, 'stash', topic, id, body: document)
    end

    def perform_set! topic, id, document
      request(:post, 'stash', topic, id, body: document)
    end

    def perform_delete topic, id=nil
      request(:delete, 'stash', topic, id)
    end
    
    def request(method, *args)
      send_request(create_request(method, *args))
    end

    def create_request method, *args
      document = (args.pop[:body] || '') if args.last.is_a?(Hash)
      path    = File.join('/v1', organization, *args.compact.map(&:to_s))
      params  = [method.to_sym, path]
      params += [MultiJson.dump(document), headers] if document

      log.debug("#{method.to_s.upcase} http://#{host}:#{port}#{path}")
      params
    end

    def send_request params
      begin
        handle_response(connection.send(*params))
      rescue Errno::ECONNREFUSED => e
        log.error("Could not connect to http://#{host}:#{port}")
        nil
      end
    end
      
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
