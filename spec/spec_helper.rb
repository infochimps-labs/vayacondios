require 'bundler'

Bundler.setup
Bundler.require

require 'goliath/test_helper'

Goliath.env = :test

RSpec.configure do |config|
  config.include Goliath::TestHelper
end


