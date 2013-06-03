require 'bundler/setup' ; Bundler.require(:test)

require 'vayacondios-server'
require 'vayacondios-client'

require 'goliath/test_helper'
Dir["spec/support/**/*.rb"].each {|f| require File.join(File.dirname(__FILE__), '..', f) }

Goliath.env = :test

require 'vayacondios/server/http_server'
