class Vayacondios
  module Rack   
    class Validation
      include Goliath::Rack::AsyncMiddleware
      
      def call(env)
        validate_route(env[:vayacondios_route])
        super(env)
      end
      
      def validate_route(route)
        raise Goliath::Validation::Error.new(400, "All requests must be sent to a path like /v1/ORGANIZATION/(event[s]|stash[es])/[TOPIC[/ID]]") if route.blank?
        raise Goliath::Validation::Error.new(400, "An organization is required") if route[:organization].blank?
        raise Goliath::Validation::Error.new(400, "A type is required") if route[:type].blank?
        
        case route[:type]
        when 'stash'
          raise Goliath::Validation::Error.new(400, "Require a topic when addressing a stash") if route[:topic].blank?
        when 'stashes'
        when 'event'
          raise Goliath::Validation::Error.new(400, "Require a topic when addressing an event") if route[:topic].blank?
        when 'events'
          raise Goliath::Validation::Error.new(400, "Require a topic when addressing events") if route[:topic].blank?
        else
          raise Goliath::Validation::Error.new(400, "Unknown type of request")
        end
      end
      
    end
  end
end
