#!/usr/bin/env ruby

require 'vayacondios-server'
require 'time'

class HttpShim < Goliath::API
  use Goliath::Rack::Heartbeat          # respond to /status with 200, OK (monitoring, etc)
  use Goliath::Rack::Tracer, 'X-Tracer' # log trace statistics
  use Goliath::Rack::Params             # parse & merge query and body parameters

  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format

  def response(env)
    # Validate path_params
    path_params = parse_path(env[Goliath::Request::REQUEST_PATH])
    return [400, {}, {error: "Bad Request"}] if !path_params.present?
      
    # Look up handler using inflection
    klass = ('vayacondios/' + path_params[:type] + '_handler').camelize.constantize

    begin
      if method_name == :update
        record = klass.new(mongo).update(env.params, path_params)
      elsif method_name == :get
        record = klass.find(mongo, path_params)
      end
    rescue Vayacondios::Error::BadRequest => ex
      return [400, {}, {error: "Bad Request"}]
    rescue Exception => ex
      puts ex
      ex.backtrace.each{|l| puts l}
    end

    if !record.present?
      [404, {}, {error: "Not Found"}]
    end
      
    [200, {}, record]
  end

  private

  # Determine the organization, type of action (config or event), the topic,
  # id, and format for the request.
  def parse_path path
    path_regex = /^\/v1\/(?<organization>[a-z]\w+)\/(?<type>config|event)(\/(?<topic>\w+)(\/(?<id>(\w+\/?)+))?)?(\/|\.(?<format>json))?$/i
    if (match = path_regex.match(path))
      {}.tap do |segments|
        match.names.each do |segment|
          segments[segment.to_sym] = match[segment]
        end
      end
    end
  end

  def method_name
    if %{PUT POST}.include?(env['REQUEST_METHOD'].upcase)
      :update
    elsif env['REQUEST_METHOD'].downcase == 'get'
      :get
    end
  end
end