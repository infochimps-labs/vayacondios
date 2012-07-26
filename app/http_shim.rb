#!/usr/bin/env ruby
require File.expand_path('../lib/boot', File.dirname(__FILE__))
require 'vayacondios'
require 'time'

class HttpShim < Goliath::API
  VERSION0_RE = /^(\/v0)?\/(?<topic>([a-z]\w+\/?)+)(\.(?<format>json))?$/i
  VERSION1_RE = /^\/v1\/(?<organization>[a-z]\w+)\/(?<type>config|event)(\/(?<topic>\w+)(\/(?<id>(\w+\/?)+))?)?(\/|\.(?<format>json))?$/i

  use Goliath::Rack::Heartbeat                     # respond to /status with 200, OK (monitoring, etc)
  use Goliath::Rack::Tracer, 'X-Tracer'            # log trace statistics
  use Goliath::Rack::Params                        # parse & merge query and body parameters
  #
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format
  
  def response(env)
    path_params = parse_path(env[Goliath::Request::REQUEST_PATH])

    if path_params.present?
      klass = ('vayacondios/' + path_params[:type] + '_handler').camelize.constantize

      if method_name == :get && !path_params[:topic].present?
        return [400, {}, {error: "Bad Request"}]
      end

      if method_name == :update
        record = klass.new(env.params, path_params).update
      elsif method_name == :get
        record = klass.get(path_params)
      end
      
      if record.present?
        [200, {}, record]
      else
        [404, {}, {error: "Not Found"}]
      end
    else
      [400, {}, {error: "Bad Request"}]
    end
  end

private

  def parse_path path
    if (match = VERSION1_RE.match(path))
      match_data_to_hash(match)
    elsif (match = VERSION0_RE.match(path)) && !/^\/?v[1-9]/.match(path) 
      match_data_to_hash(match).tap do |params|
        params[:type] = 'event'
        params[:topic]   = params[:topic].sub(/^\//, '').gsub(/[\W_]+/, '_').squeeze('_')
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

  def match_data_to_hash(match)
    match.names.inject({}){|hsh, name| hsh.merge({name.to_sym => match[name]}) }
  end

end