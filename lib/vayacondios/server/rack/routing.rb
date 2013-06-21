class Vayacondios
  module Rack

    # Parses the request path to determine routing parameters like
    # organization, topic, ID, &c.
    class Routing

      include Goliath::Rack::AsyncMiddleware

      # Sets the `vayacondios_route` properties by parsing the request path.
      #
      # @param [Hash] env the request environment
      def call(env)
        super(env.merge(vayacondios_route: parse_path(env[Goliath::Request::REQUEST_PATH])))
      end

      # Parses the `vayacondios_route` properties fromt the request path.
      #
      # Uses a regular expression with named capture groups to fill
      # out the content of the route.  Will detect
      #
      # * `organization` for the request
      # * `type` of the request: `stash`, `event`, `stashes`, or `events`
      # * `topic` for the request if present
      # * `id` for the request if present
      # 
      # @param [String] path
      # @return [Hash] the `vayacondios_route` properties
      def parse_path(path)
        path_regex = /^\/v2\/(?<organization>[a-z]\w+)\/(?<type>stash(?:es)?|events?)(\/(?<topic>[-\.\w]+)(\/(?<id>([-\.\w+]\/?)+))?)?(\/|\.(?<format>json))?$/i
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
