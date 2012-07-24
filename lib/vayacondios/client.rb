require 'net/http'
require 'json'

class Vayacondios
  class Client
    class Error < StandardError; end
    
    def initialize(host, port, organization=nil)
      @host = host
      @port = port
      @organization = organization if organization
    end
    
    def organization(organization)
      @organization = organization
    end
    
    def uri
      return @uri if @uri

      uri_str  = "http://#{@host}:#{@port}/v1"
      uri_str += "/#{@organization}" if @organization
      @uri ||= URI(uri_str)
    end
    
    def fetch(type, id)
      request(:get, type, id)
    end
    
    def insert(document, type = nil, id = nil)
      id   ||= document.delete(:_id)   || document.delete('_id')
      type ||= document.delete(:_type) || document.delete('_type')
      
      request(:post, type, id, document)
    end
    
  private
    
    def request(method, type, id=nil, document={})
      path = File.join(uri.path, type.to_s, *id.to_s.split(/\W/))

      http = Net::HTTP.new(uri.host, uri.port)

      params  = [method.to_sym, path]
      params += [document.to_json, {'Content-Type' => 'application/json'}] unless document.empty?

      response = http.send *params

      if Net::HTTPSuccess === response
        JSON.parse(response.body) rescue response.body
      else
        raise Error.new("Error (#{response.code}) while #{method.to_s == 'get' ? 'fetching' : 'inserting'} document: " + response.body)
      end
    end
  end
end
  