class Vayacondios
  module Rack
    class AssumeJSON
      include Goliath::Rack::AsyncMiddleware
      
      def call(env)
        env['CONTENT_TYPE'] =
          'application/json' unless env.has_key? 'CONTENT_TYPE'
        super env
      end
    end
  end
end
