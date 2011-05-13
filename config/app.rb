config[:server] = {
  :nodename => ENV['NODENAME'],
  :hostname => `hostname`.chomp,
  :program  => File.expand_path($0),
  :version  => `git log | head -n1`.chomp.split[1],
  :pid      => Process.pid,
}

config[:statsd_logger] = {
  :name => 'brocephalus',
  :host => '127.0.0.1',
  :port => '8125'
}

environment(:production) do
  config['broham'] = EventMachine::Synchrony::ConnectionPool.new(:size => 20) do
    EM::Mongo::Connection.new('localhost', 27017, 1, {:reconnect_in => 1}).db('broham_test')
  end
end

environment(:development) do
  config['broham'] = EM::Mongo::Connection.new('localhost', 27017, 1, {:reconnect_in => 1}).db('broham_test')
end

environment(:test) do
  config['broham'] = EM::Mongo::Connection.new('localhost', 27017, 1, {:reconnect_in => 1}).db('broham_test')
end
