#!/usr/bin/env ruby
require File.expand_path('../lib/boot', File.dirname(__FILE__))
require 'vayacondios'
require 'vayacondios/statsd_receiver'

class HttpShim < Goliath::API
  use Goliath::Rack::Heartbeat                     # respond to /status with 200, OK (monitoring, etc)
  use Goliath::Rack::Tracer, 'X-Tracer'            # log trace statistics
  use Goliath::Rack::Params                        # parse & merge query and body parameters
  #
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Render, 'json'     # auto-negotiate response format
  #
  # plugin Vayacondios::StatsdReceiver               # listen like statsd would

  # db = EM::Mongo::Connection.new('localhost').db('my_database')
  # collection = db.collection('my_collection')

  def bucket_name
    env[Goliath::Request::REQUEST_PATH].sub(/^\//, '').gsub(/[\W_]+/, '_')
  end

  # Pass the request on to host given in config[:forwarder]
  def response(env)
    result = collection.insert(env.params)
    [200, {}, { :result => { :bucket => bucket_name, :id => result }}.to_json]
  end

protected
  def db
    @db ||= env.config['vayacondios_dev']
  end

  def collection
    db.collection(bucket_name)
  end

end
