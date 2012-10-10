require 'bundler/setup' ; Bundler.require

Dir["spec/support/**/*.rb"].each {|f| require File.join(File.dirname(__FILE__), '..', f) }

require 'goliath/test_helper'

Goliath.env = :test
