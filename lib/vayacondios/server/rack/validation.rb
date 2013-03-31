class Vayacondios
  module Rack   
    class Validation
      include Goliath::Rack::AsyncMiddleware
      
      def initialize(app, opts = {})
        @app  = app
        @opts = opts
      end
      
      def call(env)
        raise Goliath::Validation::Error.new(400, "All requests must be sent to a path like /v1/ORG/(EVENT|CONFIG)/TOPIC[/ID]") unless valid_paths? env[:vayacondios_route]
        @app.call(env)
      end
      
      def valid_paths?(path)
        # use @opts for validation later
        path.nil? ? false : true
      end
      
    end
  end
end
