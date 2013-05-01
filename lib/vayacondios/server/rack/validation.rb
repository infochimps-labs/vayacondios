class Vayacondios
  module Rack   
    class Validation
      include Goliath::Rack::AsyncMiddleware
      
      def initialize(app, opts = {})
        @app  = app
        @opts = opts
      end
      
      def call(env)
        validate_route(env[:vayacondios_route])
        @app.call(env)
      end
      
      def validate_route(route)
        raise Goliath::Validation::Error.new(400, "All requests must be sent to a path like /v1/ORG/(event|config)/TOPIC[/ID]") unless route
        case route[:type]
        when 'config'
          # FIXME add validation for configs
        when 'event'
          # FIXME add validation for events
        end
      end
      
    end
  end
end
