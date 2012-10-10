class Vayacondios
  module Rack
    class Path
      include Goliath::Rack::AsyncMiddleware
      
      def call(env)
        path_params = parse_path(env[Goliath::Request::REQUEST_PATH])
        super env.merge(vayacondios_path: path_params)
      end
      
      def parse_path(path)
        path_regex = /^\/v1\/(?<organization>[a-z]\w+)\/(?<type>config|event|itemset)(\/(?<topic>\w+)(\/(?<id>(\w+\/?)+))?)?(\/|\.(?<format>json))?$/i
        if (match = path_regex.match(path))
          {}.tap do |segments|
            match.names.each do |segment|
              segments[segment.to_sym] = match[segment]
            end
          end
        end
      end
    end
  end
end
