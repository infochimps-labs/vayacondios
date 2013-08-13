class Vayacondios
  module Rack

    # Parses parameters in the request.
    #
    # Will parse parameters from the query string as well as from the
    # request body.
    #
    # Rack gets unhappy when the parameters are anything other than a
    # Hash but we want clients to be able to send non-Hash-like
    # request bodies.  To support this case, the request's params are
    # stored into the `_document` key of the params, to be fetched
    # later by Vayacondios::HttpServer#document.
    class Params < Goliath::Rack::Params

      # Parses the parameters of the request.
      #
      # @param [Hash] env the request environment
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
                            MultiJson.decode(body) rescue body
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
