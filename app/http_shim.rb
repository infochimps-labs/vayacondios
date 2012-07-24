#!/usr/bin/env ruby
require File.expand_path('../lib/boot', File.dirname(__FILE__))
require 'vayacondios'
require 'vayacondios/statsd_receiver'
require 'time'

class HttpShim < Goliath::API
  autoload :Version0, 'http_shim/version0'
  autoload :Version1, 'http_shim/version1'
  
  VERSION0_RE = /^(\/v0)?\/(?<bucket>([a-z]\w+\/?)+)(\.(?<format>[a-z0-9]+))/i
  VERSION1_RE = /^\/v1\/(?<organization>[a-z]\w+)\/(?<type>config|event)(?<id>(\/\w+)*)(\/|\.(?<format>[a-z0-9]+))?$/i

  use Goliath::Rack::Heartbeat                     # respond to /status with 200, OK (monitoring, etc)
  use Goliath::Rack::Tracer, 'X-Tracer'            # log trace statistics
  use Goliath::Rack::Params                        # parse & merge query and body parameters
  #
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format
  
  def response(env)
    path = env[Goliath::Request::REQUEST_PATH]

    if (match = VERSION1_RE.match(path))
      delegate Version1, env, match
    elsif (match = VERSION0_RE.match(path))
      delegate Version0, env, match
    else
      [400, {}, {}]
    end
  end

private

  def delegate(klass, env, match)
    klass.new.response(env, match_data_to_hash(match))
  end

  def match_data_to_hash(match)
    match.names.inject({}){|hsh, name| hsh.merge({name.to_sym => match[name]}) }
  end

end