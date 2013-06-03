require 'configliere'

Settings.define 'mongo.host',     :default => 'localhost',        :description => 'Hostname for MongoDB server'
Settings.define 'mongo.port',     :default => '27017',            :description => 'Port for MongoDB server'
Settings.define 'mongo.database', :default => 'vayacondios_test', :description => 'Name of database to use'

Settings.read(File.join File.dirname(__FILE__), '..', '..', 'config', 'vayacondios.yaml')
Settings.resolve!

def mongo_connection
  @mongo_connection ||= Mongo::Connection.new(Settings[:mongo][:host],Settings[:mongo][:port])
end

def mongo &block
  fail unless block
  yield mongo_connection.db(Settings[:mongo][:database])
end

def clean_mongo!
  mongo do |db|
    db.collections.select {|c| c.name !~ /system/ }.each { |c| c.drop }
  end
end

RSpec.configure do |config|
  config.before :each do
    clean_mongo!
  end

  config.after :all do
    clean_mongo!
  end
end
