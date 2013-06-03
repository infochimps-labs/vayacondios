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
        raise Goliath::Validation::Error.new(400, "All requests must be sent to a path like /v1/ORG/(event|stash)/TOPIC[/ID]") unless route
        case route[:type]
        when 'stash'
          raise Goliath::Validation::Error.new(400, "Require an organization when addressing a stash") unless route[:organization]
          raise Goliath::Validation::Error.new(400, "Require a topic when addressing a stash") unless route[:topic]
        when 'event'
          raise Goliath::Validation::Error.new(400, "Require an organization when addressing an event") unless route[:organization]
          raise Goliath::Validation::Error.new(400, "Require a topic when addressing an event") unless route[:topic]
        end
      end
      
    end
  end
end
