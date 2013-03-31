class Vayacondios
  module Rack
    class ExtractMethods
      include Goliath::Rack::AsyncMiddleware
      
      def call(env)
        method_name = extract_method(env)
        super env.merge(vayacondios_method: method_name)
      end
      
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
