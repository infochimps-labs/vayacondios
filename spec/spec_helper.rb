# Set this constant so we can easily find the configuration file to
# launch Vayacondios with.
VCD_ROOT = File.join(File.dirname(__FILE__), '..')

require 'bundler/setup' ; Bundler.require(:test)


require 'configliere'

Settings.define 'mongo.host',     :default => 'localhost',        :description => 'Hostname for MongoDB server'
Settings.define 'mongo.port',     :default => '27017',            :description => 'Port for MongoDB server'
Settings.define 'mongo.database', :default => 'vayacondios_test', :description => 'Name of database to use'

Settings.read(File.join File.dirname(__FILE__), '..', 'config', 'spec.yml')
Settings.resolve!

# require 'rack/test'

require 'goliath/test_helper'

if ENV['VAYACONDIOS_COV']
  require 'simplecov'
  SimpleCov.start
end

require 'vayacondios-server'
require 'vayacondios-client'

Dir["spec/support/**/*.rb"].each {|f| require File.join(File.dirname(__FILE__), '..', f) }

Goliath.env = :test

require 'vayacondios/server/http_server'
