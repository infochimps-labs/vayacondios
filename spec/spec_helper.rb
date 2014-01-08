# Set this constant so we can easily find the configuration file to
# launch Vayacondios with.
VCD_ROOT = File.expand_path('../..', __FILE__)

require 'bundler/setup' ; Bundler.require(:test)

require 'configliere'

Settings.define 'database.host', default: 'localhost',        description: 'Hostname for MongoDB server'
Settings.define 'database.port', default: '27017',            description: 'Port for MongoDB server'
Settings.define 'database.name', default: 'vayacondios_test', description: 'Name of database to use'
Settings.read File.expand_path('../config/spec.yml', __FILE__)
Settings.resolve!

require 'goliath/test_helper'

if ENV['VAYACONDIOS_COV']
  require 'simplecov'
  SimpleCov.start
end

require 'vayacondios-server'
require 'vayacondios-client'

Dir['spec/support/**/*.rb'].each{ |f| require File.join(File.dirname(__FILE__), '..', f) }

require 'vayacondios/server/http_server'

RSpec.configure do |c|
  c.include MongoHelper

  c.before(:each){ clean_mongo! }
  c.after(:each) { clean_mongo! }
end
