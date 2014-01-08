require 'vayacondios-server'

module Vayacondios::Server

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
  # passed to the `vcd-server` program.
  #
  # It **simultaneously** is required to read a configuration file
  # from disk.  This configuration file is aware of the Rack
  # environment the code is running in so it can take
  # environment-specific actions like creating single-connections in
  # test/development but using a pool of shared connections in
  # production mode.  The default file is located in the Vayacondios
  # source distribution at `config/vcd-server.rb`.
  # 
  class Api < Goliath::API

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
      BANNER

      opts.separator ''
      opts.separator 'Database options:'

      options[:database] ||= {}
      db_options = options[:database]
      db_options[:driver]      ||= 'mongo'
      db_options[:host]        ||= 'localhost'
      db_options[:port]        ||= 27017
      db_options[:name]        ||= 'vayacondios_development'
      db_options[:connections] ||= 20

      opts.on('-d', '--database.driver NAME', "Database driver (default: #{db_options[:driver]})"){ |val| db_options[:driver] = val }
      opts.on('-h', '--database.host HOST', "Database host (default: #{db_options[:host]})"){ |val| db_options[:host] = val }
      opts.on('-o', '--database.port PORT', Integer, "Database port (default: #{db_options[:port]})"){ |val| db_options[:port] = val }
      opts.on('-D', '--database.name NAME', "Database name (default: #{db_options[:name]})"){ |val| db_options[:name] = val }
      opts.on('-n', '--database.connections NUM', Integer, "Number of database connections to make (default: #{db_options[:connections]}).  Only used in 'production' environment"){ |val| db_options[:connections] = val }

      options[:config] ||= File.expand_path('../../../../config/vcd-server.rb', __FILE__)
    end

    use Goliath::Rack::Heartbeat
    use Infochimps::Rack::ApiVersion,                 Vayacondios::VERSION, api: 'Vayacondios'
    use Infochimps::Rack::ForceContentType,           'application/json'
    use Goliath::Rack::Formatters::JSON
    use Goliath::Rack::Render
    use Goliath::Rack::Params
    use Goliath::Rack::Validation::RequestMethod,     %w[ GET POST PUT PATCH DELETE ]
    use Infochimps::Rack::ControlMethods,             'POST'   => :create,
                                                      'GET'    => :retrieve,
                                                      'PATCH'  => :update,
                                                      'PUT'    => :update,
                                                      'DELETE' => :delete
    use Infochimps::Rack::Validation::Routes,         /^
                                                      \/v2
                                                      \/(?<organization>[a-z][-_\w]+)
                                                      \/(?<type>[-\.\w]+)
                                                      (\/(?<topic>[-\.\w]+)
                                                      (\/(?<id>([-\.\w+]\/?)+))?)?
                                                      (\/|\.(?<format>json))?
                                                      $/ix,
                                                      '/v2/<organization>/<type>/<topic>/<id>.<format>'
    use Infochimps::Rack::Validation::RouteHandler,   :type, 'stash'   => StashHandler, 
                                                             'stashes' => StashesHandler,
                                                             'event'   => EventHandler,
                                                             'events'  => EventsHandler
    use Infochimps::Rack::Validation::RequiredRoutes, :type, 'stash'     => :topic,
                                                             /^events?$/ => :topic

    # The document part of the request, e.g. - params that came
    # directly from its body.
    #
    # Goliath::Rack::Params dumps all non-Hash types that were JSON
    # parsed under this header. By accessing the #document this way
    # we allow for non-Hash bodies to be sent as requests.
    #
    # @return [Hash,Array,String,Fixnum,nil] any native JSON datatype
    def document
      params['_json'] || params
    end

    # Deliver a response for the request.
    #
    # Uses the method set by Infochimps::Rack::ControlMethods to
    # determine which action to call on the handler determined by
    # Infochimps::Rack::Validation::RouteHandler
    #
    # Traps Goliath::Validation::Errors by returning the appropriate
    # response.
    #
    # Traps all other errors by responding with a 500.
    #
    # @param [Hash] env the current request environment
    def response env
      body = handler.new(logger, db).call(control_method, routes, document)
      [200, {}, body]
    rescue Goliath::Validation::Error => e
      return [e.status_code, {}, { error: e.message }]
    rescue Document::Error => e
      return [400, {}, { error: e.message }]
    rescue => e
      env.logger.error "#{e.class} -- #{e.message}"
      e.backtrace.each{ |line| env.logger.error line }
      return [500, {}, { error: "#{e.class} -- #{e.message}" }]
    end
  end
  
end
