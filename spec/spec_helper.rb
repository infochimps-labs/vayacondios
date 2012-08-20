# ENV["RACK_ENV"] ||= 'test'
# RACK_ENV = ENV["RACK_ENV"] unless defined?(RACK_ENV)
#
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_group "Client", "lib/vayacondios/client"
    add_group "Server", "lib/vayacondios/server"
  end
end
