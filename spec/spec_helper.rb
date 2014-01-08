# Set this constant so we can easily find the configuration file to
# launch Vayacondios with.
VCD_ROOT = File.expand_path('../..', __FILE__)

require 'bundler/setup' ; Bundler.require(:test)

require 'configliere'

Settings.define 'database.host',   default: 'localhost',        description: 'Hostname for database server'
Settings.define 'database.port',   default: '27017',            description: 'Port for database server'
Settings.define 'database.name',   default: 'vayacondios_test', description: 'Name of database to use'
Settings.define 'database.driver', default: 'mongo',            description: 'Database driver'
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

require 'vayacondios/server/api'

RSpec.configure do |c|
  c.include DatabaseHelper

  c.before(:each){ clean_db! }
  c.after(:each) { clean_db! }
end
