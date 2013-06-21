class Vayacondios
  module Rack

    # Validates that the request route and method conform to the
    # Vayacondios API.
    class Validation
      include Goliath::Rack::AsyncMiddleware

      # Validates the request environment conforms to the Vayacondios
      # API.
      #
      # @param [Hash] env the request environment
      def call(env)
        validate_route(env[:vayacondios_route])
        super(env)
      end

      # Validates the route conforms to the Vayacondios API.
      #
      # @param [Hash] route the Vayacondios route
      # @raise [Goliath::Validation::Error] if the request path doesn't match a path that conforms to the Vayacondios API
      # @raise [Goliath::Validation::Error] if the `organization` of the request is missing
      # @raise [Goliath::Validation::Error] if the request has no `type` (`stash`, `event`, `stashes`, or `events`)
      # @raise [Goliath::Validation::Error] if the request has an unknown `type`
      # @raise [Goliath::Validation::Error] if the request `type` requires a `topic` and none is provided
      def validate_route(route)
        raise Goliath::Validation::Error.new(400, "All requests must be sent to a path like /v2/ORGANIZATION/(event[s]|stash[es])/[TOPIC[/ID]]") if route.blank?
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
