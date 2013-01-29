require 'socket'

class Vayacondios

  # Used for sending events to a Zabbix server.
  #
  # An 'event' from Vayacondios' perspective is an arbitrary Hash.
  #
  # An 'event' from Zabbix's perspective is a tuple of values:
  #
  # * time
  # * host
  # * key
  # * value
  #
  # This client will accept a Vayacondios event and internally
  # translate it into a set of Zabbix events.
  #
  # @example A CPU monitoring notification
  #
  #   notify "foo-server.example.com", cpu: {
  #     util: {
  #       user: 0.20,
  #       idle: 0.70,
  #       sys:  0.10
  #     },
  #     load: 1.3
  #   }
  #
  # would get turned into the following events when written to Zabbix:
  #
  # @example The CPU monitoring notification translated to Zabbix events
  #
  # [
  #   { host: "foo-server.example.com", key: "cpu.util.user", value: 0.20 }
  #   { host: "foo-server.example.com", key: "cpu.util.idle", value: 0.70 },
  #   { host: "foo-server.example.com", key: "cpu.util.sys",  value: 0.10 },
  #   { host: "foo-server.example.com", key: "cpu.load",      value: 1.3  }
  # ]
  #
  # Zabbix will interpret the time as the time it receives each event.
  #
  # The following links provide details on the protocol used by Zabbix
  # to receive events:
  #
  # * https://www.zabbix.com/forum/showthread.php?t=20047&highlight=sender
  # * https://gist.github.com/1170577
  # * http://spin.atomicobject.com/2012/10/30/collecting-metrics-from-ruby-processes-using-zabbix-trappers/?utm_source=rubyflow&utm_medium=ao&utm_campaign=collecting-metrics-zabix
  class ZabbixClient
    include Gorillib::Builder

    attr_accessor :socket

    field :host, String,  :default => 'localhost', :doc => "Host for the Zabbix server"
    field :port, Integer, :default => 10051,       :doc => "Port for the Zabbix server"

    # Insert events to a Zabbix server.
    #
    # The `topic` will be used as the name of the Zabbix host to
    # associate event data to.
    #
    # As per the documentation for the [Zabbix sender
    # protocol](https://www.zabbix.com/wiki/doc/tech/proto/zabbixsenderprotocol),
    # a new TCP connection will be created for each event.
    #
    # @param [String] topic
    # @param [Hash] cargo
    # Array<Hash>] text
    def insert topic, cargo={}
      self.socket = TCPSocket.new(host, port)
      send_request(topic, cargo)
      handle_response
      self.socket.close
    end

    private

    # :nodoc
    def send_request topic, cargo
      socket.write(payload(topic, cargo))
    end

    # :nodoc
    def handle_response
      header = socket.recv(5)
      if header == "ZBXD\1"
        data_header = socket.recv(8)
        length      = data_header[0,4].unpack("i")[0]
        response    = MultiJson.load(socket.recv(length))
        puts response["info"]
      else
        puts "Invalid response: #{header}"
      end
    end

    # :nodoc
    def payload topic, cargo={}
      body = body_for(topic, cargo)
      header_for(body) + body
    end

    # :nodoc
    def body_for topic, cargo={}
      MultiJson.dump({request: "sender data", data: zabbix_events_from(topic, cargo) })
    end

    # :nodoc
    def header_for body
      length = body.bytesize
      "ZBXD\1".encode("ascii") + [length].pack("i") + "\x00\x00\x00\x00"
    end

    # :nodoc
    def zabbix_events_from topic, cargo, scope=''
      events = []
      case cargo
      when Hash
        cargo.each_pair do |key, value|
          events += zabbix_events_from(topic, value, new_scope(scope, key))
        end
      when Array
        cargo.each_with_index do |item, index|
          events += zabbix_events_from(topic, item, new_scope(scope, index))
        end
      else
        events << event_body(topic, scope, cargo)
      end
      events
    end

    # :nodoc
    def new_scope(current_scope, new_scope)
      [current_scope, new_scope].map(&:to_s).reject(&:empty?).join('.')
    end

    # :nodoc
    def event_body topic, scope, cargo
      value = case cargo
      when Hash  then cargo[:value]
      when Array then cargo.first
      else cargo
      end
      { host: topic, key: scope, value: value }
    end
    
  end
end

