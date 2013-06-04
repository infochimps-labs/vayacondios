# This configuration script provides several example configurations of
# Vayacondios server.
#
# You can use any of these environments by specifying the
# --environment or -e flag to `vcd-server`.
#
# @see Vayacondios::HttpServer for where the MongoDB connection is
# passed to the rest of the application code.

# The production environment uses EventMachine::Synchrony to define a
# shared pool of open connections to MongoDB.  The size of this pool
# can be on the command-line with the --mongo_connections option.
environment(:production) do
  logger.info("Using #{options[:mongo_connections]} connections to #{options[:mongo_host]}:#{options[:mongo_port]}/#{options[:mongo_database]}")
  config['mongo'] = EventMachine::Synchrony::ConnectionPool.new(:size => options[:mongo_connections]) do
    conn = EM::Mongo::Connection.new(options[:mongo_host], options[:mongo_port], 1, {:reconnect_in => 1})
    conn.db(options[:mongo_database])
  end
end

# The development environment uses a single MongoDB connection.
environment(:development) do
  logger.info("Using Mongo database #{options[:mongo_host]}:#{options[:mongo_port]}/#{options[:mongo_database]}")
  conn = EM::Mongo::Connection.new(options[:mongo_host],options[:mongo_port], 1, {:reconnect_in => 1})
  config['mongo'] = conn.db(options[:mongo_database])
end

# The test environment does not read its options from the command line
# but from a Configliere Settings object which is defined.
#
# @see spec/spec_helper.rb which defines and initializes the Settings object
environment(:test) do
  logger.info("Using Mongo database #{options[:mongo_host]}:#{options[:mongo_port]}/#{options[:mongo_database]}")
  conn = EM::Mongo::Connection.new(Settings[:mongo][:host],Settings[:mongo][:port], 1, {:reconnect_in => 1})
  config['mongo'] = conn.db(Settings[:mongo][:database])
end
