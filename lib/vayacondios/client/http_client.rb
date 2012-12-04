class Vayacondios
  class HttpClient
    include Gorillib::Model

    field :host,         String,  :default => 'localhost'
    field :port,         Integer, :default => 8000
    field :organization, String,  :default => 'infochimps'
    
    class Error < StandardError; end

    def uri
      return @uri if @uri

      uri_str  = "http://#{host}:#{port}/v1"
      uri_str += "/#{organization}" if organization
      @uri ||= URI(uri_str)
    end
    
    def fetch(type, id)
      request(:get, type, id)
    end
    
    def insert(document = {}, type = nil, id = nil)
      id   ||= document.delete(:_id)   || document.delete('_id')
      type ||= document.delete(:_type) || document.delete('_type')
      
      request(:post, type, id, MultiJson.dump(document))
    end
    
  private
    
    def request(method, type, id = nil, document = nil)
      path    = File.join(uri.path, type.to_s, *id.to_s.split(/\W/))
      http    = Net::HTTP.new(uri.host, uri.port)

      params  = [method.to_sym, path]
      params += [document, {'Content-Type' => 'application/json'}] unless document.nil?
      
      response = http.send *params

      if Net::HTTPSuccess === response
        MultiJson.load(response.body) rescue response.body
      else
        raise Error.new("Error (#{response.code}) while #{method.to_s == 'get' ? 'fetching' : 'inserting'} document: " + response.body)
      end
    end
  end
end
  
