class Vayacondios
  module Rack
    class Params < Goliath::Rack::Params

      def retrieve_params(env)
        params = {}
        params.merge!(::Rack::Utils.parse_nested_query(env['QUERY_STRING']))

        if env['rack.input']
          post_params = ::Rack::Utils::Multipart.parse_multipart(env)
          unless post_params
            body = env['rack.input'].read
            return params if body.empty?
            env['rack.input'].rewind

            post_params = case(env['CONTENT_TYPE'])
                          when Goliath::Rack::URL_ENCODED then
                            ::Rack::Utils.parse_nested_query(body)
                          when Goliath::Rack::JSON_ENCODED then
                            MultiJson.decode(body)
                          else
                            {}
                          end
            if post_params.is_a?(Hash)
              params.merge!(post_params)
            else
              params['_document'] = post_params
            end
          end
        end
        params
      end
      
    end
  end
end
