class Vayacondios
  module Rack
    class JSONize
      include Goliath::Rack::AsyncMiddleware

      def call(env)
        env.logger.debug("Started #{env[Goliath::Request::REQUEST_METHOD]} \"#{env[Goliath::Request::REQUEST_PATH]}\" for #{env[Goliath::Request::REMOTE_ADDR]} as JSON")
        env['CONTENT_TYPE'] = 'application/json'
        super(env)
      end

      def post_process(env, status, headers, body)
        return [status, headers, body] if env["REQUEST_PATH"] == '/status'
        headers['Content-Type'] = 'application/json'
        body                    = [MultiJson.encode(body) + "\n"]
        [status, headers, body]
      end
      
    end
  end
end
