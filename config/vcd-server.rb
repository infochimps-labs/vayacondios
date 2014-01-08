# This configuration script provides several example configurations of
# Vayacondios server.
#
# You can use any of these environments by specifying the
# --environment or -e flag to `vcd-server`.
#
# @see Vayacondios::HttpServer for where the database connection is
# passed to the rest of the application code.

# The production environment uses EventMachine::Synchrony to define a
# shared pool of open connections to the database. The size of this pool
# can be on the command-line with the --database.connections option.
db_options = options[:database]

environment(:production) do
  logger.info("Opening #{db_options[:connections]} connections to #{db_options[:host]}:#{db_options[:port]} using #{db_options[:driver]} driver.")
  config['db'] = EventMachine::Synchrony::ConnectionPool.new(size: db_options[:connections]) do
    driver = Vayacondios::Server::Driver.retrieve db_options[:driver]
    driver.connect db_options
  end
end

# The development environment uses a single database connection.
environment(:development) do
  logger.info("Connecting to #{db_options[:host]}:#{db_options[:port]} using #{db_options[:driver]} driver.")
  driver = Vayacondios::Server::Driver.retrieve db_options[:driver]
  config['db'] = driver.connect db_options
end

# The test environment does not read its options from the command line
# but from a Configliere Settings object which is defined.
#
# @see spec/spec_helper.rb which defines and initializes the Settings object
environment(:test) do
  logger.info("Connecting to #{Settings[:database][:host]}:#{Settings[:database][:port]} using #{Settings[:database][:driver]} driver.")
  driver = Vayacondios::Server::Driver.retrieve Settings[:database][:driver]
  config['db'] = driver.connect Settings[:database]
end
