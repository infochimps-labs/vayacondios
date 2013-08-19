require 'digest/md5'
require 'ostruct'

class Vayacondios
  module Rack

    # This middleware piece provides an adapter layer between
    # contemporary versions of Vayacondios and the v1 item sets API.
    #
    # There are four supported operations on item sets in the v1
    # Vayacondios api. They all operate on paths of form
    #
    #     /v1/#{organization}/itemset/#{topic}/#{id}
    #
    # 1. fetch. This retrieves and returns an item set.
    #
    #  $ curl -XGET localhost:9000/v1/testorg/itemset/testtopic/testid
    #  > ["foo", "bar"]
    #
    # 2. create. This creates a new item set, stored as an array. It
    #            returns an empty string.
    #
    #  $ curl -XPUT localhost:9000/v1/testorg/itemset/testtopic/testid -d '["baz", "biff"]'
    #  > empty string
    #
    # 3. patch. This adds items to a set, ensuring that they only
    #           appear once in the array. It returns an empty string.
    #
    #  $ curl -XPUT -H'HTTP-X-METHOD: PATCH' \
    #          localhost:9000/v1/testorg/itemset/testtopic/testid -d '["bam", "whak"]'
    #  > empty string
    #
    # 4. delete. This removes items from a set, ensuring that they are
    #            entirely absent from the array. It returns the
    #            remaining elements.
    #
    #  $ curl -XDELETE localhost:9000/v1/testorg/itemset/testtopic/testid -d '["baz", "biff"]'
    #  > ["foo", "bar", "bam", "whak"]
    class RewriteV1
      include Goliath::Rack::AsyncMiddleware

      # Rewrites v1 requests as v2 requests. To support v1 itemsets,
      # we have to support adding to, removing from, and clobbering
      # sets. Everything must be stored as key-value pairs in v2. We
      # choose to save every item as an entry of the form
      # 
      #     md5hash => item
      #
      # within stashes. That allows adding to sets and querying them,
      # but we must also have the ability to remove many at a
      # time. For example, if we have the set
      #
      # ["foo","bar","baz","bif"]
      #
      # we may want to remove the items ["baz", "bif"] and have
      #
      # ["foo","bar"]
      #
      # To support this operation, we establish the convention that
      # item can be an empty string, representing an item that has
      # been deleted. This has a few ramifications:
      #
      # 1. It isn't possible to save empty strings in item sets
      #    anymore.
      # 2. Items are never really "removed," so actual space on disk
      #    isn't saved.
      #
      # Some of the method business has changed a bit, too, there is a
      # bit of juggling of methods.
      #
      # @param [Hash] env the request environment
      def call(env)
        orig_method = env['REQUEST_METHOD']

        env['REQUEST_METHOD'],
        env['REQUEST_PATH'],
        env['rack.input'],
        x_method,
        version = rewrite_req(env['REQUEST_METHOD'],
                              env['REQUEST_PATH'],
                              env['rack.input'],
                              env['HTTP_X_METHOD'])

        env['HTTP_X_METHOD'] = x_method unless x_method.nil?
        
        super(env, method: orig_method, version: version)
      end

      # Rewrites v2 responses as v1 responses, but only when the
      # request was a v1 request. This ensures that responses are
      # empty, for example, when creating and patching, and removes
      # empty-stringed values when returning the result of fetches and
      # removes.
      # 
      # @param [Hash] env the request environment
      # @param [Integer] status the HTTP status code of the response
      # @param [Hash] headers the HTTP headers of the response
      # @param [Object] body the upstream response body
      # @return [Array] the response
      def post_process(env, status, headers, body, args)
        body = (body.first.nil? || body.first.empty?) ? {} : MultiJson.decode(body.first)
        case args.fetch(:version)
        when 1 then rewrite_resp(args.fetch(:method), status, headers, body)
        when 2 then [status, headers, body]
        end
      end

      private

      #---------------------------------------------------------------------------------------------

      # Rewrites the v1 request method, path, body_stream, and
      # x_method. v2 requests are passed on unmodified.
      #
      # @param [String] method incoming request HTTP method.
      # @param [String] path incoming request path
      #
      # @return [Array] possibly modified versions of all of its
      #         inputs, with an appended version number of the
      #         incoming request.
      def rewrite_req(method, path, body_stream, x_method)

        # ignore non-v1 requests
        if (v1_path = parse_path(path)).nil?
          [method, path, body_stream, x_method, version(path)]

        else
          item_set = parse_body_stream(body_stream)

          new_method, new_x_method =
            case method
            when /DELETE/i then ['PUT', nil]
            when /PUT/i then
              x_method.to_s.upcase == 'PATCH' ? ['PUT', 'PATCH'] : ['POST', nil]
            else [method, x_method]
            end

          new_body_stream = body_stream.reopen(
              MultiJson.encode(Hash[item_set.map do |it|
                                      [Digest::MD5.hexdigest(it), item_repr(method, it)]
                                    end]))

          new_path = v1_path.nil? ? path : v2_path_str(v1_path)

          [new_method, new_path, new_body_stream, nil, 1]
        end
      end

      # This method must know about the incoming HTTP method
      # from the v1 request: the way the response is rewritten is
      # dependent on it.
      #
      # @param [String] method HTTP method from incoming v1 request
      # @param [Integer] status HTTP status from Vayacondios v2 response
      # @param [Hash] headers HTTP headers from Vayacondios v2 response
      # @param [Hash] body decoded (represented as JSON hash) version of v2 response
      # 
      # @return the possibly modified versions of status, headers, and
      # body.
      def rewrite_resp(method, status, headers, body)
        case status
          when 200..299
          case method
          when /(DELETE|GET)/i
            [status, headers, MultiJson.encode(body.values.reject(&:empty?).to_a)]
          else
            [status, headers, '']
          end

        when 404
          [status, headers, '{"error":"Not Found"}']
        end
      end

      #---------------------------------------------------------------------------------------------

      # Changes the formatting of an item appropriately so it can be
      # put into a stash.
      #
      # @param [String] incoming v1 method HTTP method
      # @param [String] id item
      #
      # @return the representation of an "item" (v1 concept) in a
      #         "stash" (v2 concept).
      def item_repr(method, it)
        case method
        when /DELETE/i then ''
        else it
        end
      end

      # Parses the body of an incoming v1 request.
      # 
      # @param [StringIO] body_stream stream containing the body of a
      #        v1 request.
      # @return an array corresponding to the item set encoded in an
      #         incoming v1 request.
      def parse_body_stream(body_stream)
        body = body_stream.read; body_stream.rewind
        body.empty? ? [] : MultiJson.decode(body)
      end

      # Parses the path from an incoming v1 request.
      #
      # @param [String] path incoming v1 request
      # 
      # @return an OpenStruct object with organization, type, topic,
      #         and id fields corresponding to appropriate values from
      #         the path.
      def parse_path(path)
        /^
         \/v1
         \/(?<organization>[a-z][-_\w]+)
         \/(?:itemset)
         \/(?<topic>[-\.\w]+)
         \/(?<id>[-\.\w]+)
         \/?
         $/ix.match(path){|match| OpenStruct.new(match.names.zip(match.captures)).freeze}
      end

      # @param path incoming request. could be v1, v2, or something else.
      # 
      # @return the version of a request.
      def version path
        path[/^\/v([^\/]+)/, 1].to_i
      end

      # Creates a v2 path string.
      # 
      # @param [OpenStruct] v1_path an ostruct containing
      #        'organization', 'topic', and 'id' fields corresponding
      #        to the decoded parts of the incoming v1 request.
      #        
      # @return a v2 path string given a parsed v1 string.
      def v2_path_str(v1_path)
        "/v2/#{v1_path.organization}/stash/#{v1_path.topic}/#{v1_path.id}"
      end
    end
  end
end
