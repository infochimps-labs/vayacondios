require 'bundler/setup' ; Bundler.require(:test)

require 'goliath/test_helper'
require 'mongo'

if ENV['VAYACONDIOS_COV']
  require 'simplecov'
  SimpleCov.start do
    add_group 'Library', 'lib/'
    add_group 'Test',    '(spec|features)/'
  end
end

WITH_MONGO = ENV['WITH_MONGO']

require 'vayacondios-server'
require 'vayacondios-client'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each{ |f| require f }

Goliath.env = :test

require 'vayacondios/server/api'

RSpec.configure do |c|
  c.include Goliath::TestHelper
end
