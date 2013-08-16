require 'vayacondios-server'

class Vayacondios

  # Implements the Vayacondios server API.
  #
  # ## Setup
  #
  # Once the Goliath server has booted, this class is handed control
  # to process web requests.  It uses a set of Rack-aware and
  # Goliath-friendly plugins to accomplish some of the edges stuff
  # like routing, parsing params, validating, &c.
  #
  # ## Request Loop
  #
  # When handling an actual request, it has to do four things:
  #
  # * determine which handler class to instantiate to handle the request
  # * determine the full set of params contained in the request
  # * call the appropriate method on the new handler, passing in these params
  # * handle any errors that bubble up
  #
  # ## Configuration
  #
  # Goliath is kind of weirdly hard to configure nicely.  This class
  # is also required to define an #options_parser method which is
  # momentarily handed control at bootup time to interpret options
  # pased to the `vcd-server` program.
  #
  # It **simultaneously** is required to read a configuration file
  # from disk.  This configuration file is aware of the Rack
  # environment the code is running in so it can take
  # environment-specific actions like creating single-connections in
  # test/development but using a pool of shared connections in
  # production mode.  The default file is located in the Vayacondios
  # source distribution at `config/vcd-server.rb`.
  # 
  class HttpServer < Goliath::API

    # Defines options and usage information.
    def options_parser opts, options
      opts.banner = <<-BANNER.gsub(/^ {8}/, '').strip
        usage: vcd-server [--param=value|--param|-p value|-p]

        Vayacondios server lets any system that can speak JSON over HTTP read
        and write configuration and events.

        It provides the following HTTP endpoints, all of which assume a
        JSON-encoded request body.

        Events:
          GET    /v2/ORG/event/TOPIC/ID
          POST   /v2/ORG/event/TOPIC[/ID]      (announce)
          GET    /v2/ORG/events/TOPIC          (events)

        Stashes:
          GET    /v2/ORG/stash/TOPIC[/ID]      (get)
          PUT    /v2/ORG/stash/TOPIC[/ID]      (set)
          POST   /v2/ORG/stash/TOPIC[/ID]      (set!)
          DELETE /v2/ORG/stash/TOPIC[/ID]      (delete)
          GET    /v2/ORG/stashes               (stashes)
          PUT    /v2/ORG/stashes               (set_many)
          POST   /v2/ORG/stashes               (set_many!)
          DELETE /v2/ORG/stashes               (delete_many)

        The server requires MongoDB as a data store.
      BANNER

      opts.separator ''
      opts.separator 'MongoDB options:'

      options[:mongo_host]        = 'localhost'
      options[:mongo_port]        = 27017
      options[:mongo_database]    = 'vayacondios_development'
      options[:mongo_connections] = 20

      opts.on('-h', '--host HOST',                "MongoDB host (default: #{options[:mongo_host]})")         { |val| options[:mongo_host]     = val }
      opts.on('-o', '--mongo_port PORT', Integer, "MongoDB port (default: #{options[:mongo_port]})")         { |val| options[:mongo_port]     = val }
      opts.on('-D', '--database NAME',            "MongoDB database (default: #{options[:mongo_database]})") { |val| options[:mongo_database] = val }
      opts.on('-n', '--connections NUM', Integer, "Number of MongoDB connections to make (default: #{options[:mongo_connections]}).  Only used in 'production' environment") { |val| options[:mongo_connections] = val }

      options[:config] ||= File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'vcd-server.rb')
    end

    use Goliath::Rack::Heartbeat                                                # respond to /status with 200, OK (monitoring, etc)
    use Vayacondios::Rack::RewriteV1                                            # rewrite v1 requests to valid v2 requests
    use Vayacondios::Rack::JSONize                                              # JSON input & output
    use Vayacondios::Rack::Params                                               # parse query string and message body into params hash
    use Goliath::Rack::Validation::RequestMethod, %w[GET POST PUT PATCH DELETE]   # only allow these methods
    
    use Vayacondios::Rack::Routing                                              # parse path into parameterized pieces
    use Vayacondios::Rack::ExtractMethods                                       # interpolate GET, PUT into :create, :update, etc
    use Vayacondios::Rack::Validation                                           # validation

    use Goliath::Rack::Render                                                   # auto-negotiate response format

    # The document part of the request, e.g. - params that came
    # directly from its body.
    #
    # Something somewhere in Rack is unhappy when receiving
    # non-Hash-like records via a JSON-formatted request body. So that
    # Vayacondios::Rack::Params takes a non-Hash-like request body and
    # turns it into a Hash with a single key: _document.
    #
    # This hack does **not** affect the client-side: clients can still
    # send non-Hash-like JSON documents and they will be interpreted
    # as intended.
    #
    # @return [Hash,Array,String,Fixnum,nil] any native JSON datatype
    def document
      params['_document'] || params
    end

    # The handler to use for the request.
    #
    # Introspects on the route set by Vayacondios::Rack::Routing and
    # determines whether to use the Vayacondios::StashHandler or the
    # Vayacondios::EventHandler.
    #
    # @return [StashHandler, EventHandler]
    # @raise [Goliath::Validation::Error] if no handler can be found
    def handler
      case env[:vayacondios_route][:type]
      when /^stash/i
        Vayacondios::StashHandler.new(env.logger, mongo)
      when /^event/i
        Vayacondios::EventHandler.new(env.logger, mongo)
      else
        raise Goliath::Validation::Error.new(400, "Invalid type: <#{env[:vayacondios_route][:type]}>")
      end
    end

    # Deliver a response for the request.
    #
    # Uses the method set by Vayacondios::Rack::ExtractMethods to
    # determine which action to call on the #handler.
    #
    # Traps Goliath::Validation::Errors by returning the appropriate
    # response.
    #
    # Traps all other errors by responding with a 500.
    #
    # @param [Hash] env the current request environment
    def response(env)
      body = handler.send(env[:vayacondios_method], env[:vayacondios_route], document)
      [200, {}, body]
    rescue Goliath::Validation::Error => e
      return [e.status_code, {}, {error: e.message}]
    rescue Vayacondios::Document::Error => e
      return [400, {}, {error: e.message}]
    rescue => e
      env.logger.error "#{e.class} -- #{e.message}"
      e.backtrace.each{ |line| env.logger.error(line) }
      return [500, {}, {error: "#{e.class} -- #{e.message}"}]
    end
  end
  
end
