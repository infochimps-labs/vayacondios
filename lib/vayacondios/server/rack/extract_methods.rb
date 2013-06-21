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

      # Extracts the `vayacondios_method` from the HTTP verb.
      #
      # @param [Hash] env the request environment
      # @return [Symbol] the Vayacondios method
      def extract_method env        
        return unless env['REQUEST_METHOD']
        case env['REQUEST_METHOD'].upcase
        when 'PUT'
          case env['HTTP_X_METHOD'].to_s.upcase
          when 'PATCH'  then :patch
          when 'DELETE' then :delete
          else               :update
          end
        when 'GET'    then :show
        when 'POST'   then :create
        when 'PATCH'  then :patch
        when 'DELETE' then :delete
        else nil
        end
      end
    end
  end
end
