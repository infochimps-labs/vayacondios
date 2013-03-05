#!/usr/bin/env ruby

require 'vayacondios-server'

class HttpShim < Goliath::API
  use Vayacondios::Rack::AssumeJSON                                      # assume application/json content type
  use Goliath::Rack::Tracer, 'X-Tracer'                                  # log trace statistics
  use Goliath::Rack::Params                                              # parse query string and message body into params hash
  use Goliath::Rack::Validation::RequestMethod, %w[GET PUT PATCH DELETE] # only allow these methods
  use Vayacondios::Rack::ExtractMethods                                  # interpolate GET, PUT into :create, :update, etc
  use Vayacondios::Rack::Path                                            # parse path into parameterized pieces
  use Vayacondios::Rack::PathValidation                                  # validate the existence of env[:vayacondios_path]
  use Goliath::Rack::Formatters::JSON                                    # JSON output formatter
  use Goliath::Rack::Render                                              # auto-negotiate response format
  use Goliath::Rack::Heartbeat                                           # respond to /status with 200, OK (monitoring, etc)

  def response(env)
    path_params = env[:vayacondios_path]
    klass = ('vayacondios/' + path_params[:type] + '_handler').camelize.constantize

    begin
      case env[:vayacondios_method]
        
      when :show
        record = klass.find(mongo, path_params)
        [200, {}, MultiJson.dump(record.body)]

      when :update
        record = klass.new(mongo).update(env['params'], path_params)
        [200, {}, nil]
        
      when :patch
        record = klass.new(mongo).patch(env['params'], path_params)
        [200, {}, nil]

      when :delete
        record = klass.find(mongo, path_params).destroy(env['params'])
        [200, {}, MultiJson.dump(record.body)]
      end
    rescue Vayacondios::Error::NotFound => ex
      return [404, {}, MultiJson.dump({ error: "Not Found" })]
    rescue Vayacondios::Error::BadRequest => ex
      return [400, {}, MultiJson.dump({ error: "Bad Request" })]
    rescue StandardError => ex
      puts ex
      ex.backtrace.each{ |l| puts l }
    end
  end
end
