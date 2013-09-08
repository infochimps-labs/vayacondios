class Vayacondios
  module Rack

    # Interprets the HTTP verb and as a Vayacondios request method.
    class ExtractMethods
      include Goliath::Rack::AsyncMiddleware

      # Sets the `vayacondios_method` property of the environment for
      # downstream apps.
      #
      # @param [Hash] env the request environment
      def call(env)
        super env.merge(vayacondios_method: extract_method(env))
      end

      # Extracts the `vayacondios_method` from combination of HTTP
      # verb and existing `vayacondios_route`.
      #
      # @param [Hash] env the request environment
      # @return [Symbol] the Vayacondios method
      def extract_method env
        # Respect the X_METHOD over the METHOD
        return unless request_method = (env['HTTP_X_METHOD'] || env['REQUEST_METHOD']).to_s.upcase

        # Treat PATCH like PUT because many clients don't do PATCH
        # well.
        request_method = "PUT" if request_method == "PATCH"
        
        return unless type = (env[:vayacondios_route] && env[:vayacondios_route][:type])

        # This is basically the routing table which connects HTTP verb
        # & URL to "controller action"
        env[:vayacondios_method] = case [request_method, type]
        when %w[GET    event],  %w[GET    stash]   then :show
        when %w[GET    events], %w[GET    stashes] then :search
        when %w[POST   event],  %w[POST   stash]   then :create
        when %w[PUT    stash]                      then :update
        when %w[DELETE stash]                      then :delete
        when %w[POST   stashes]                    then :replace_many
        when %w[PUT    stashes]                    then :update_many
        when %w[DELETE stashes]                    then :delete_many
        else
          raise Goliath::Validation::Error.new(404, "No route for HTTP method <#{request_method}> for type <#{type}>")
        end
      end
    end
  end
end
