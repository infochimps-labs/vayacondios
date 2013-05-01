require 'net/http'

class Vayacondios
  class HttpClient < Client

    Error = Class.new(StandardError)

    attr_accessor :host
    attr_accessor :port
    attr_accessor :organization

    def initialize options={}
      super(options)
      self.host         = (options[:host] || 'localhost').to_s
      self.port         = (options[:port] || 9000).to_i
      self.organization = options[:organization].to_s
    end

    def perform_announce topic, event, id=nil
      request(:post, 'event', topic, id, event)
    end

    def perform_get topic, id
      request(:get, 'config', topic, id)
    end

    def perform_set topic, id, config
      request(:put, 'config', topic, id, config)
    end

    def perform_set! topic, id, config
      request(:post, 'config', topic, id, config)
    end

    def perform_delete topic, id
      request(:delete, 'config', topic, id)
    end
    
    def request(method, *args)
      document = args.pop if args.last.is_a?(Hash)
      
      path    = File.join('/v1', organization, *args.compact.map(&:to_s))
      params  = [method.to_sym, path]
      params += [MultiJson.dump(document), {'Content-Type' => 'application/json'}] if document

      log.debug("#{method.to_s.upcase} http://#{host}:#{port}#{path}")
      make_request(params)
    end
    
    protected

    def make_request params
      begin
        handle_response(Net::HTTP.new(host, port).send(*params), options)
      rescue Errno::ECONNREFUSED => e
        log.error("Could not connect to http://#{host}:#{port}")
      end
    end
      
    def handle_response response, options={}
      case response
      when Net::HTTPOK
        MultiJson.load(response.body)
      when Net::HTTPNotFound
        log.debug("#{response.code} -- #{response.class}")
      else
        log.debug("#{response.code} -- #{response.class}")
        log.error MultiJson.load(response.body)["error"]
      end
    end
    
  end
end
