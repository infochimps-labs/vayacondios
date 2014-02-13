# All examples assume a running Vayacondios server on localhost:3467
# with a backing database.
#
# bundle exec ruby examples/configuration.rb
require 'vayacondios/client'

# Setting up connection options
#
# Vcd::Client::ConnectionOpts reads from the following in order:
# * library defaults (Vcd::Client::ConnectionOpts.defaults
# * /etc/vayacondios/vayacondios.yml
# * $PWD/config/vayacondios.yml
# * any overlays applied using ConnectionOpts.overlay

# Change the base file_name from 'vayacondios.yml'
Vcd::Client::ConnectionOpts.base_filename = 'foo.yml'

# Change the config load order
Vcd::Client::ConnectionOpts.load_order = %w[ global local ]

# Load order calls methods that expect either a Hash or a String filename returned
Vcd::Client::ConnectionOpts.define_singleton_method(:local) do
  '/path/to/local/config_file'
end

# Override configuration for further Vcd connections
Vcd::Client::ConnectionOpts.overlay(adapter: :net_http)

# As soon as the options are used they become resolved and cannot be changed
puts Vcd::Client::ConnectionOpts[:adapter]
puts Vcd::Client::ConnectionOpts.resolved?
Vcd::Client::ConnectionOpts.overlay(adapter: :em_http)
Vcd::Client::ConnectionOpts.resolve!
puts Vcd::Client::ConnectionOpts.resolved_settings

# Create a new connection with options
Vcd::Client::Connection.factory(host: 'foo', port: 1234)

# Mixin the http modules and get access to a memoized connection and client methods
class MyClass
  include Vcd::Client::HttpRead
  include Vcd::Client::HttpWrite
  include Vcd::Client::HttpAdmin
end

my_class = MyClass.new
puts my_class.http_connection

# override memoized connection options for this instance only
puts my_class.configure_connection(host: 'localhost')

# utilize client http methods
response = my_class.set('id', nil, foo: 'bar')
puts response.body
response = my_class.unset('id')
puts response.body
