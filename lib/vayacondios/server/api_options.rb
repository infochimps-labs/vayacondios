module Vayacondios::Server
  module ApiOptions

    def options_parser opts, options
      opts.banner = <<-BANNER.gsub(/^ {8}/, '').strip
        usage: vcd-server [--param=value|--param|-p value|-p]

        Vayacondios server lets any system that can speak JSON over HTTP read
        and write configuration and events.

        It provides the following HTTP endpoints, all of which assume a
        JSON-encoded request body.

        Events:
          GET    /v2/ORG/event/TOPIC/ID
          POST   /v2/ORG/event/TOPIC[/ID]      (announce)
          DELETE /v2/ORG/event/TOPIC/ID
          GET    /v2/ORG/events/TOPIC          (events)
          DELETE /v2/ORG/events/TOPIC

        Stashes:
          GET    /v2/ORG/stash/TOPIC[/ID]      (get)
          POST   /v2/ORG/stash/TOPIC[/ID]      (set!)
          DELETE /v2/ORG/stash/TOPIC[/ID]      (delete)
          GET    /v2/ORG/stashes               (stashes)
          DELETE /v2/ORG/stashes               (delete_many)
      BANNER

      opts.separator ''
      opts.separator 'Database options:'

      options[:database] = {}
      db_options = options[:database]
      defaults = DbConfig.defaults[Goliath.env]
      opts.on('-d', '--database.driver NAME', "Database driver (default: #{defaults[:driver]})") do |name|
        db_options[:driver] = name
      end
      opts.on('-h', '--database.host HOST', "Database host (default: #{defaults[:host]})") do |host|
        db_options[:host] = host
      end
      opts.on('-o', '--database.port PORT', Integer, "Database port (default: #{defaults[:port]})") do |port|
        db_options[:port] = port
      end
      opts.on('-D', '--database.name NAME', "Database name (default: #{defaults[:name]})") do |name|
        db_options[:name] = name
      end
      opts.on('-n', '--database.connections NUM', Integer, "Number of database connections to make (default: #{defaults[:connections]}). Production only") do |num|
        db_options[:connections] = num
      end

      options[:config] = File.join(Vayacondios.library_dir, 'config/vcd-server.rb')
      options[:port]   = Vayacondios::DEFAULT_SERVER_PORT
    end

  end
end
