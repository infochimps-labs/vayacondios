#!/usr/bin/env ruby

require 'gorillib/logger/log'
require 'vayacondios-server'

class HttpShim < Goliath::API
  use Goliath::Rack::Heartbeat                                           # respond to /status with 200, OK (monitoring, etc)
  use Vayacondios::Rack::JSONize
  use Goliath::Rack::Tracer, 'X-Tracer'                                  # log trace statistics
  use Vayacondios::Rack::Params                                          # parse query string and message body into params hash
#  use Goliath::Rack::Params                                              # parse query string and message body into params hash
  use Goliath::Rack::Validation::RequestMethod, %w[GET PUT PATCH DELETE] # only allow these methods
  use Vayacondios::Rack::ExtractMethods                                  # interpolate GET, PUT into :create, :update, etc
  use Vayacondios::Rack::Path                                            # parse path into parameterized pieces
  use Vayacondios::Rack::PathValidation                                  # validate the existence of env[:vayacondios_path]
  use Goliath::Rack::Formatters::JSON                                    # JSON output formatter
  use Goliath::Rack::Render                                              # auto-negotiate response format

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

  def response(env)
    path_params = env[:vayacondios_path]
    klass = ('vayacondios/' + path_params[:type] + '_handler').camelize.constantize

    Log.info("received request #{env['REQUEST_METHOD']} #{env['REQUEST_URI']}")
    Log.info("params: #{document}")

    begin
      case env[:vayacondios_method]
        
      when :show
        record = klass.find(mongo, path_params)
        [200, {}, record.body]

      when :update
        record = klass.new(mongo).update(document, path_params)
        [200, {}, nil]
        
      when :patch
        record = klass.new(mongo).patch(document, path_params)
        [200, {}, nil]

      when :delete
        record = klass.find(mongo, path_params).destroy(document)
        [200, {}, record.body]
      end
    rescue Vayacondios::Error::NotFound => ex
      return [404, {}, { error: "Not Found" }]
    rescue Vayacondios::Error::BadRequest => ex
      return [400, {}, { error: "Bad Request" }]
    rescue StandardError => ex
      puts ex
      ex.backtrace.each{ |l| puts l }
    end
  end
end
