environment(:production) do
  logger.info("Using #{options[:mongo_connections]} connections to #{options[:mongo_host]}:#{options[:mongo_port]}/#{options[:mongo_database]}")
  config['mongo'] = EventMachine::Synchrony::ConnectionPool.new(:size => options[:mongo_connections]) do
    conn = EM::Mongo::Connection.new(options[:mongo_host], options[:mongo_port], 1, {:reconnect_in => 1})
    conn.db(options[:mongo_database])
  end
end

environment(:development) do
  logger.info("Using Mongo database #{options[:mongo_host]}:#{options[:mongo_port]}/#{options[:mongo_database]}")
  conn = EM::Mongo::Connection.new(options[:mongo_host],options[:mongo_port], 1, {:reconnect_in => 1})
  config['mongo'] = conn.db(options[:mongo_database])
end

environment(:test) do
  logger.info("Using Mongo database #{options[:mongo_host]}:#{options[:mongo_port]}/#{options[:mongo_database]}")
  conn = EM::Mongo::Connection.new(options[:mongo_host],options[:mongo_port], 1, {:reconnect_in => 1})
  config['mongo'] = conn.db(options[:mongo_database])
end
