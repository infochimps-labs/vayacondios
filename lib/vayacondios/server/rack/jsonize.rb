class Vayacondios
  module Rack

    # Sets the `Content-Type` of the request and response to
    # `application/json`.
    class JSONize
      include Goliath::Rack::AsyncMiddleware

      # Sets the `Content-Type` header to `application/json` so
      # downstream parameter parsing will work correctly.
      #
      # @param [Hash] env the request environment
      def call(env)
        env.logger.debug("Started #{env[Goliath::Request::REQUEST_METHOD]} \"#{env[Goliath::Request::REQUEST_PATH]}\" for #{env[Goliath::Request::REMOTE_ADDR]} as JSON")
        env['CONTENT_TYPE'] = 'application/json'
        super(env)
      end

      # Sets the `Content-Type` header to `application/json` and
      # serializes the response body to a JSON string.
      #
      # Will *not* do this if the request was sent to `/status` which
      # is expected to just return the string `OK`.
      #
      # @param [Hash] env the request environment
      # @param [Integer] status the HTTP status code of the response
      # @param [Hash] headers the HTTP headers of the response
      # @param [Object] body the upstream response body
      # @return [Array] the response
      def post_process(env, status, headers, body)
        return [status, headers, body] if env["REQUEST_PATH"] == '/status'
        headers['Content-Type'] = 'application/json'
        body                    = [MultiJson.encode(body) + "\n"]
        [status, headers, body]
      end
      
    end
  end
end
