require 'net/http'
require 'multi_json'

class Vayacondios
  class Client
    class ItemSet
      def initialize host, port, organization=nil, topic=nil, id=nil
        @host         = host
        @port         = port
        @organization = organization
        @topic        = topic
        @id           = id
      end

      def fetch organization=nil, topic=nil, id=nil
        resp = execute_request(_req(:fetch, nil, organization, topic, id)) and
          resp["contents"]
      end

      def update ary, organization=nil, topic=nil, id=nil
        execute_request(_req(:update, ary, organization, topic, id))
      end

      def create ary, organization=nil, topic=nil, id=nil
        execute_request(_req(:create, ary, organization, topic, id))
      end

      def remove ary, organization=nil, topic=nil, id=nil
        execute_request(_req(:remove, ary, organization, topic, id))
      end


      private

      def execute_request req
        resp = Net::HTTP.start(@host, @port) do |http|
          http.request(req)
        end.body
        result = MultiJson.decode(resp) unless resp.nil? or resp.empty?
        (result.respond_to?(:has_key?) and result.has_key? "error") ? nil : result
      end

      def path organization, topic, id
        if ((the_organization = (organization || @organization)).nil? ||
            (the_topic        = (topic        || @topic       )).nil? ||
            (the_id           = (id           || @id          )).nil?)
          raise ArgumentError.new("must provide organization, topic, and id!")
        end

        ['/v1', the_organization, 'itemset', the_topic, the_id].join("/")
      end

      # This is the only private method that is tested.
      def _req type, ary=nil, organization=nil, topic=nil, id=nil

        the_path = path(organization, topic, id)
        headers = {"content-type" => "application/json"}
        headers.merge!("x-method" => "PATCH") if type == :update
 
        case type
        when :fetch  then Net::HTTP::Get
        when :create then Net::HTTP::Put
        when :update then Net::HTTP::Put
        when :remove then Net::HTTP::Delete
        else         raise ArgumentError.new("invalid type: #{type}")
        end.new(the_path, headers).tap do |req|
          req.body = MultiJson.encode(contents: ary) unless type == :fetch
        end
      end
    end
  end
end
