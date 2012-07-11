require 'net/http'
require 'json'

class Vayacondios
  class Client
    class Error < StandardError; end
    
    def initialize(host, port, organization=nil, type=nil)
      @host = host
      @port = port
      @type = type if type
      @organization = organization if organization
    end
    
    def organization(organization)
      self.class.new(@host, @port, organization)
    end
    
    def config
      self.class.new(@host, @port, @organization, :config)
    end
    
    def uri
      return @uri if @uri

      uri_str  = "http://#{@host}:#{@port}/v1"
      uri_str += "/#{@organization}" if @organization
      uri_str += "/#{@type}" if @type
      @uri ||= URI(uri_str)
    end
    
    def fetch(id)
      request(:get, id)
    end
    
    def insert(document, id=nil)
      id ||= document.delete(:_id) || document.delete('_id')
      
      request(:post, id, document)
    end
    
  private
    
    def request(method, id=nil, document={})
      path = File.join(uri.path, *id.to_s.split(/\W/))
      http = Net::HTTP.new(uri.host, uri.port)

      params  = [method.to_sym, path]
      params += [document.to_json, {'Content-Type' => 'application/json'}] unless document.empty?

      response = http.send *params

      if Net::HTTPSuccess === response
        JSON.parse(response.body) rescue response.body
      else
        raise Error.new("Error (#{response.code}) while inserting document: " + response.body)
      end
    end
  end
end
  