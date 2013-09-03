require 'gorillib/logger/log'
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
        execute_request(_req(:fetch, nil, organization, topic, id))
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
        begin
          resp = Net::HTTP.start(@host, @port) do |http|
            http.request(req)
          end.body
          result = MultiJson.decode(resp) unless resp.nil? or resp.empty?
          (result.respond_to?(:has_key?) and result.has_key? "error") ? nil : result
        rescue StandardError => ex
          Log.warn("problem contacting vayacondios: #{ex.message}")
          Log.debug(ex.backtrace.join("\n"))
          Log.debug("response: #{resp.inspect}")
          nil
        end
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
          req.body = MultiJson.encode(ary) unless type == :fetch
        end
      end
    end

    # Subclasses should implement the remove_items(arr) and
    # add_items(arr) methods, both of which will be called with arrays
    # when the items in an itemset change. The run method polls the
    # provided itemset at a specified interval and calls these methods
    # appropriately.
    class ItemSetListener
      POLL_WAIT_SEC=2

      def initialize itemset, poll_wait_sec = POLL_WAIT_SEC
        @itemset = itemset
        @items = []
        @poll_wait_sec = poll_wait_sec
      end

      def run
        setup
        loop do
          new_items = @itemset.fetch || []

          Log.debug "currently configured: #{@items.inspect}"
          Log.debug "new items: #{new_items.inspect}"

          add_items(new_items - @items)
          remove_items(@items - new_items)

          @items = new_items

          sleep @poll_wait_sec
        end
        teardown
      end

      protected

      def add_items
        raise NoMethodError.new("class #{self.class.name} must override add_items")
      end

      def remove_items
        raise NoMethodError.new("class #{self.class.name} must override remove_items")
      end

      def setup() end
      def teardown() end

    end
  end
end
