class Vayacondios
  module Rack   
    class PathValidation
      include Goliath::Rack::AsyncMiddleware
      
      def initialize(app, opts = {})
        @app = app ; @opts = opts
      end
      
      def call(env)
        return [400, {}, MultiJson.dump({ error: "Bad Request. Format path is <host>/v1/<org>/event/<topic>" })] unless valid_paths? env[:vayacondios_path]
        @app.call(env)
      end
      
      def valid_paths?(path)
        # use @opts for validation later
        path.nil? ? false : true
      end
      
    end
  end
end
