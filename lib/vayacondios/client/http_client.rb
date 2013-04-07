class Vayacondios
  class HttpClient

    Error = Class.new(StandardError)

    attr_accessor :log
    attr_accessor :host
    attr_accessor :port
    attr_accessor :organization

    def initialize log, host, port, organization
      self.log          = log
      self.host         = host
      self.port         = port
      self.organization = organization
    end

    def uri
      return @uri if @uri
      uri_str  = "http://#{host}:#{port}/v1/#{organization}"
      @uri ||= URI(uri_str)
    end
    
    def event(topic, id)
      request(:get, 'event', topic, id)
    end

    def config(topic, id)
      request(:get, 'config', topic, id)
    end

    def event! topic, document={}, id=nil
      request(:post, 'event', topic, id, document)
    end

    def config! topic, id, document={}
      request(:post, 'config', topic, id, document)
    end

    def set_config topic, id, document={}
      request(:put, 'config', topic, id, document)
    end

    def delete_config topic, id
      request(:delete, 'config', topic, id)
    end
    
    private
    
    def request(method, type, topic, id = nil, document = nil)
      path    = File.join(uri.path.to_s, type.to_s, topic.to_s, id.to_s)
      http    = Net::HTTP.new(uri.host, uri.port)

      params  = [method.to_sym, path]
      params += [MultiJson.dump(document), {'Content-Type' => 'application/json'}] unless document.nil?

      log.debug("#{method.to_s.upcase} http://#{uri.host}:#{uri.port}#{path}")
      
      handle_response(http.send(*params))
    end

    def handle_response response
      log.debug("#{response.code} -- #{response.class}")
      case response
      when Net::HTTPOK
        MultiJson.load(response.body)
      when Net::HTTPNotFound
      else
        log.error(response.body)
      end
      
    end
    
  end
end
