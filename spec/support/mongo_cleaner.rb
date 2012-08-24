require 'mongo'
require 'configliere'

Settings.define :app_name,    :default => 'vayacondios', :description => 'Name to key on for tracer stats, statsd metrics, etc.'
Settings.define 'mongo.host', :default => 'localhost',   :description => 'Mongo hostname'
Settings.define 'mongo.port', :default => '27017',       :description => 'Mongo port'

Settings.read(File.join File.dirname(__FILE__), '..', '..', 'config', 'vayacondios.yaml')
Settings.resolve!

def clean_mongo
  conn = Mongo::Connection.new(Settings[:mongo][:host],Settings[:mongo][:port])
  mongo = conn.db(Settings[:mongo][:database])
  mongo.collections.select {|c| c.name !~ /system/ }.each { |c| c.drop }
  conn.close
end

RSpec.configure do |config|
  config.before :each do
    clean_mongo
  end

  config.after :all do
    clean_mongo
  end
end
