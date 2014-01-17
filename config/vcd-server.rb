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
Vayacondios::Server::DbConfig.overlay options[:database]

environment(:production) do
  db_options = Vayacondios::Server::DbConfig.env :production
  driver = Vayacondios::Server::Driver.retrieve db_options[:driver]
  logger.info("Opening #{db_options[:connections]} connections to #{db_options[:host]}:#{db_options[:port]} using #{driver}.")
  config['db'] = EventMachine::Synchrony::ConnectionPool.new(size: db_options[:connections]) do
    driver.connect db_options.merge(log: logger)
  end
end

# The development environment uses a single database connection.
environment(:development) do
  db_options = Vayacondios::Server::DbConfig.env :development
  driver = Vayacondios::Server::Driver.retrieve db_options[:driver]
  logger.info("Connecting to #{db_options[:host]}:#{db_options[:port]} using #{driver}.")
  config['db'] = driver.connect db_options.merge(log: logger)
end

environment(:test) do
  db_options = Vayacondios::Server::DbConfig.env :test
  driver = Vayacondios::Server::Driver.retrieve db_options[:driver]
  logger.info("Connecting to #{db_options[:host]}:#{db_options[:port]} using #{driver}.")
  config['db'] = driver.connect db_options.merge(log: logger)
end
