require 'bundler/setup' ; Bundler.require(:test)

require 'goliath/test_helper'

if ENV['VAYACONDIOS_COV']
  require 'simplecov'
  SimpleCov.start
end

require 'vayacondios-server'
require 'vayacondios-client'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each{ |f| require f }

Goliath.env = :test
Vayacondios::Server::DbConfig.overlay(test: { name: 'peepee' })

require 'vayacondios/server/api'

RSpec.configure do |c|
  c.include Goliath::TestHelper
  c.include DatabaseHelper
end
