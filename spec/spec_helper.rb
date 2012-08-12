ENV["RACK_ENV"] ||= 'test'
RACK_ENV = ENV["RACK_ENV"] unless defined?(RACK_ENV)

require 'bundler/setup' ; Bundler.require(:default, :development, :test)
require 'rspec/autorun'

require File.join(File.dirname(__FILE__), '../lib/boot')
$LOAD_PATH.unshift(File.dirname(__FILE__))

if ENV['VCD_COV']
  require 'simplecov'
  SimpleCov.start
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

require 'goliath'
require 'em-synchrony'
require 'goliath/test_helper'
require 'support/test_helper'

# Requires custom matchers & macros, etc from files in ./support/ & subdirs
Dir[Goliath.root_path("spec/support/**/*.rb")].each {|f| require f}

# Configure rspec
RSpec.configure do |config|
  config.include Goliath::TestHelper, :example_group => {
    :file_path => /spec/
  }
end
