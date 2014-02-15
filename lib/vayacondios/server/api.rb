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
    include ApiOptions

    plugin Goliath::Chimp::Plugin::ActivityMonitor, window: 30

    use Goliath::Rack::Heartbeat
    use Goliath::Chimp::Rack::Formatters::JSON
    use Goliath::Chimp::Rack::ForceContentType,           'application/json'
    use Goliath::Rack::Render
    use Goliath::Rack::Params
    use Goliath::Chimp::Rack::ApiVersion,                 Vayacondios::GEM_VERSION, api: 'Vayacondios'
    use Goliath::Chimp::Rack::ServerMetrics,              env_key: { 'routes' => :type }, default: 'other'
    use Goliath::Rack::Validation::RequestMethod,         %w[ GET POST PUT PATCH DELETE ]
    use Goliath::Chimp::Rack::ControlMethods,             'POST'   => :create,
                                                          'GET'    => :retrieve,
                                                          'PATCH'  => :update,
                                                          'PUT'    => :update,
                                                          'DELETE' => :delete
    use Goliath::Chimp::Rack::Validation::Routes,         /^
                                                            \/#{Vayacondios::API_VERSION}
                                                            \/(?<organization>[a-z][-_\w]+)
                                                            \/(?<type>[-\.\w]+)
                                                            (\/(?<topic>[-\.\w]+)
                                                            (\/(?<id>([-\.\w+]\/?)+))?)?
                                                          $/ix,
                                                          "/#{Vayacondios::API_VERSION}/<organization>/<type>/<topic>/<id>"
    use Goliath::Chimp::Rack::Validation::RouteHandler,   :type, 'stash'   => StashHandler,
                                                                 'stashes' => StashesHandler,
                                                                 'event'   => EventHandler,
                                                                 'events'  => EventsHandler,
                                                                 'stream'  => StreamHandler
    use Goliath::Chimp::Rack::Validation::RequiredRoutes, :type, 'stash'     => :topic,
                                                                 /^events?$/ => :topic,
                                                                 'stream'    => :topic

    # The document part of the request, e.g. - params that came
    # directly from its body.
    #
    # Goliath::Rack::Params dumps all non-Hash types that were JSON
    # parsed under this header. By accessing the #document this way
    # we allow for non-Hash bodies to be sent as requests.
    #
    # @return [Hash,Array,String,Fixnum,nil] any native JSON datatype
    def document
      params.has_key?('_json') ? params['_json'] : params
    end

    # Assign a callback to the stream endpoint. Some of the Rack
    # logic is recreated because of the way streaming data works.
    def open_stream(env, hndlr)
      env[:subscription] = hndlr.stream_data{ |data| env.stream_send MultiJson.dump(data).concat("\n") }
    end

    # Make sure to remove any outstanding streaming connections
    # when the client disconnects
    def on_close env
      return unless env[:subscription]
      env.delete(:subscription).close_stream!
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
      h = handler.new(logger, db)
      open_stream(env, h) if routes[:type] == 'stream'
      body = h.call(control_method, routes, document)
      [200, {}, body]
    rescue Goliath::Validation::Error => e
      return [e.status_code, {}, { error: e.message }]
    rescue Document::Error => e
      return [400, {}, { error: e.message }]
    rescue => e
      logger.error "#{e.class} -- #{e.message}"
      e.backtrace.each{ |line| logger.error line }
      return [500, {}, { error: "#{e.class} -- #{e.message}" }]
    end
  end
  
end
