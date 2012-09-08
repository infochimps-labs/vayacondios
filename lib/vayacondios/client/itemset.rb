require 'net/http'
require 'multi_json'

class Vayacondios
  class Client
    class ItemSet
      def initialize host, port, organization, topic, id
        @host = host
        @port = port

        @path = "/v1/#{organization}/itemset/#{topic}/#{id}"
      end

      # Exposed for testing.
      def _req type, ary = nil
        case type
        when :fetch  then
          Net::HTTP::Get.new(@path)
        when :create then
          (req = Net::HTTP::Put.new(@path)).body = MultiJson.encode(ary)
          req
        when :update then
          (req = Net::HTTP::Put.new(@path, [["http_x_method", "PATCH"]])).body = MultiJson.encode(ary)
          req
        end
      end

      def fetch
        execute_request(_req(:fetch))
      end

      def update ary
        execute_request(_req(:update, ary))
      end

      def create ary
        execute_request(_req(:create, ary))
      end

      private

      def execute_request req
        resp = Net::HTTP.start(@host, @port) do |http|
          http.request(req)
        end.body
        MultiJson.decode(resp) unless resp.nil? or resp.empty?
      end
    end
  end
end
