#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '../lib/boot')
require 'brocephalus'
require 'brocephalus/statsd_receiver'

class HttpShim < Goliath::API
  use Goliath::Rack::Heartbeat                     # respond to /status with 200, OK (monitoring, etc)
  use Goliath::Rack::Tracer, 'X-Tracer'            # log trace statistics
  use Goliath::Rack::Params                        # parse & merge query and body parameters
  #
  plugin Brocephalus::StatsdReceiver               # listen like statsd would

  # Pass the request on to host given in config[:forwarder]
  def response(env)
    [200, {}, 'hi mom']
  end

end
