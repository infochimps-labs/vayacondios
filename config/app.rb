def ENV.root_path(*args)
  File.expand_path(File.join(File.dirname(__FILE__), '..', *args))
end

require 'configliere'
Settings.define :app_name,    :default => 'vayacondios', :description => 'Name to key on for tracer stats, statsd metrics, etc.'
Settings.define 'mongo.host', :default => 'localhost',   :description => 'Mongo hostname'
Settings.define 'mongo.port', :default => '27017',       :description => 'Mongo port'

Settings.read(ENV.root_path('config/vayacondios.yaml'))
Settings.resolve!

config[:server] = {
  :nodename => ENV['NODENAME'],
  :hostname => `hostname`.chomp,
  :program  => File.expand_path($0),
  :version  => `git log | head -n1`.chomp.split[1],
  :pid      => Process.pid,
}

config[:activity_stream] = Settings[:activity_stream]

environment(:production) do
  Settings[:environment] = config[:environment] = 'production'
  config['mongo'] = EventMachine::Synchrony::ConnectionPool.new(:size => 20) do
    conn = EM::Mongo::Connection.new(Settings[:mongo][:host], Settings[:mongo][:port], 1, {:reconnect_in => 1})
    conn.db(Settings[:mongo][:database])
  end
end

environment(:development) do
  Settings[:environment] = config[:environment] = 'development'
  conn = EM::Mongo::Connection.new(Settings[:mongo][:host],Settings[:mongo][:port], 1, {:reconnect_in => 1})
  config['mongo'] = conn.db(Settings[:mongo][:database])
end

def config.inspect
  self.reject{|k, v| /#{DB_NAME}/ =~ k.to_s}.inspect
end
