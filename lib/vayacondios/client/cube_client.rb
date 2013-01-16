class Vayacondios
  class CubeClient
    include Gorillib::Model

    field :host,         String,  :default => 'localhost'
    field :port,         Integer, :default => 6000
    
    class Error < StandardError; end

    def uri
      return @uri if @uri

      uri_str  = "http://#{host}:#{port}/1.0"
      @uri ||= URI(uri_str)
    end
    
    def event(topic, document = {})
      request(:post, File.join(uri.path, 'event'), MultiJson.dump(document))
    end
    
  private
    
    def request(method, path, document=nil)
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
  
