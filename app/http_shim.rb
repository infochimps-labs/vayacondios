#!/usr/bin/env ruby
require File.expand_path('../lib/boot', File.dirname(__FILE__))
require 'vayacondios'
require 'vayacondios/statsd_receiver'
require 'time'

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
    raise ArgumentError, "Must specify a bucket name in the path" unless bucket_name.present?
    document = {d: env.params}
    document[:_id] = document[:d].delete("_id") if document[:d].has_key? "_id"
    begin
      document[:t]   = Time.parse(document[:d].delete("_ts")) if document[:d].has_key? "_ts"
    rescue
      raise ArgumentError, "_ts field contained invalid time string"
    end
    document[:t] ||= Time.now
    
    result = collection.insert(document)
    [200, {}, { :result => { :bucket => bucket_name, :id => result }}]
  end

protected

  def collection
    DB.collection(bucket_name + '_events ')
  end
end
