require 'digest/md5'
require 'ostruct'

class Vayacondios
  module Rack

    class RewriteV1
      include Goliath::Rack::AsyncMiddleware

      # @param [Hash] env the request environment
      def call(env)
        orig_method = env['REQUEST_METHOD']
        env['REQUEST_METHOD'], env['REQUEST_PATH'], env['rack.input'], env['HTTP_X_METHOD'], version =
          rewrite(env['REQUEST_METHOD'], env['REQUEST_PATH'], env['rack.input'], env['HTTP_X_METHOD'])
        STDERR.puts("body being sent from call: #{env['rack.input'].read}")
        env['rack.input'].rewind
        super(env, method: orig_method, version: version)
      end

      # @param [Hash] env the request environment
      # @param [Integer] status the HTTP status code of the response
      # @param [Hash] headers the HTTP headers of the response
      # @param [Object] body the upstream response body
      # @return [Array] the response
      def post_process(env, status, headers, body, args)
        body = MultiJson.decode(body.first)
        case args.fetch(:version)
        when 1 then rewrite_resp(args.fetch(:method), status, headers, body)
        when 2 then [status, headers, body]
        end
      end

      private

      def item_repr(method, it)
        case method
        when /DELETE/i then ''
        else it
        end
      end

      def v2_path_str(v1_path)
        "/v2/#{v1_path.organization}/stashes/#{v1_path.topic}/#{v1_path.id}"
      end

      def parse_body_stream(body_stream)
        body = body_stream.read; body_stream.rewind
        puts "decoding #{body}"
        body.empty? ? [] : MultiJson.decode(body)
      end

      def parse_path(path)
        /^
         \/v1
         \/(?<organization>[a-z][-_\w]+)
         \/(?<type>itemset)
         \/(?<topic>[-\.\w]+)
         \/(?<id>[-\.\w]+)
         \/?
         $/ix.match(path){|match| OpenStruct.new(match.names.zip(match.captures)).freeze}
      end

      def version path
        path[/^\/v([^\/]+)/, 1].to_i
      end

      def rewrite_resp(method, status, headers, body)
        case method
        when /(DELETE|GET)/i
          [status, headers, MultiJson.encode(body.values.reject(&:empty?).to_a)]
        else
          [status, headers, '']
        end
      end

      def rewrite(method, path, body_stream, x_method)
        if (v1_path = parse_path(path)).nil?
          return [method, path, body_stream, x_method, version(path)]
        end

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

        result = [new_method, new_path, new_body_stream, nil, 1]
        STDERR.puts("rewritten stuff: #{result.inspect}")
        STDERR.puts("rewritten body: #{new_body_stream.read}")
        new_body_stream.rewind
        result
      end
    end
  end
end
