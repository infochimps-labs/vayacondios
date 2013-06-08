require 'vayacondios-server'

class Vayacondios
  class HttpServer < Goliath::API

    def options_parser opts, options
      opts.banner = <<BANNER
usage: vcd-server [--param=value|--param|-p value|-p]

Vayacondios server lets any system that can speak JSON over HTTP read
and write configuration and events.

It provides the following HTTP endpoints, all of which assume a
JSON-encoded request body.

Events:
  GET    /v1/ORG/event/TOPIC/ID
  POST   /v1/ORG/event/TOPIC[/ID]

Stashes:
  GET    /v1/ORG/stash/TOPIC[/ID]
  PUT    /v1/ORG/stash/TOPIC[/ID]
  POST   /v1/ORG/stash/TOPIC[/ID]
  DELETE /v1/ORG/stash/TOPIC[/ID]

The server requires MongoDB as a data store.
BANNER

      opts.separator ""      
      opts.separator "MongoDB options:"

      options[:mongo_host]        = 'localhost'
      options[:mongo_port]        = 27017
      options[:mongo_database]    = ["vayacondios", env || 'development'].compact.map(&:to_s).join('_')
      options[:mongo_connections] = 20

      opts.on('-h', '--host HOST',                "MongoDB host (default: #{options[:mongo_host]})")         { |val| options[:mongo_host]     = val }
      opts.on('-o', '--mongo_port PORT', Integer, "MongoDB port (default: #{options[:mongo_port]})")         { |val| options[:mongo_port]     = val }
      opts.on('-D', '--database NAME',            "MongoDB database (default: #{options[:mongo_database]})") { |val| options[:mongo_database] = val }
      opts.on('-n', '--connections NUM', Integer, "Number of MongoDB connections to make (default: #{options[:mongo_connections]}).  Only used in 'production' environment") { |val| options[:mongo_connections] = val }

      options[:config] ||= File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'vcd-server.rb')
    end

    use Goliath::Rack::Heartbeat                                             # respond to /status with 200, OK (monitoring, etc)
    use Vayacondios::Rack::JSONize                                           # JSON input & output
    use Vayacondios::Rack::Params                                            # parse query string and message body into params hash
    use Goliath::Rack::Validation::RequestMethod, %w[GET POST PUT PATCH DELETE]   # only allow these methods
    
    use Vayacondios::Rack::ExtractMethods                                    # interpolate GET, PUT into :create, :update, etc
    use Vayacondios::Rack::Routing                                           # parse path into parameterized pieces
    use Vayacondios::Rack::Validation                                        # validate the existence of env[:vayacondios_route]
    
    use Goliath::Rack::Render                                                # auto-negotiate response format

    def response(env)
      begin
        case env[:vayacondios_method]
          
        when :show
          [200, {}, handler.find(env[:vayacondios_route], document)]

        when :create
          [200, {}, handler.create(env[:vayacondios_route], document)]
          
        when :update
          [200, {}, handler.update(env[:vayacondios_route], document)]
          
        when :patch
          [200, {}, handler.patch(env[:vayacondios_route], document)]

        when :delete
          [200, {}, handler.delete(env[:vayacondios_route])]
        end
      rescue Goliath::Validation::Error => e
        return [e.status_code, {}, {error: e.message}]
      rescue => e
        env.logger.error "#{e.class} -- #{e.message}"
        e.backtrace.each{ |line| env.logger.error(line) }
        return [500, {}, {error: "#{e.class} -- #{e.message}", backtrace: e.backtrace}]
      end
    end

    def document
      params['_document'] || params
    end

    def handler
      ('vayacondios/' + env[:vayacondios_route][:type] + '_handler').camelize.constantize.new(env.logger, mongo)
    end

  end
end
