module Brocephalus
  # Acts as a statsd-compatible server: Aggregates values, counts and timings to
  # a remote graphite.
  #
  # @example
  #  plugin Brocephalus::StatsdReceiver
  #
  class StatsdReceiver
    attr_reader   :config
    attr_reader   :logger

    DEFAULT_CONFIG = {
      :debug             => true,
      :dump_messages     => true,
      :debug_interval    => 10.0,
      :flush_interval    => 10.0,
      :percent_threshold => 90,
      :graphite_host     => '127.0.0.1',
      :graphite_port     => 2003,
      :statsd_rcv_addr   => '0.0.0.0',
      :statsd_rcv_port   => 8125,
    }.freeze

    # Called by the framework to initialize the plugin
    #
    # @param port [Integer] Unused
    # @param config [Hash] The server configuration data
    # @param status [Hash] A status hash
    # @param logger [Log4R::Logger] The logger
    # @return [Goliath::Plugin::Latency] An instance of the Brocephalus::StatsdReceiver plugin
    def initialize(port, full_config, status, logger)
      @status = status
      @logger = logger
      @config = DEFAULT_CONFIG.merge(full_config[:statsd_receiver] || {})
      unless @config[:graphite_host] then raise "please specify a graphite host in config[:statsd_receiver][:graphite_host]" end
    end

    # Called automatically to start the plugin
    def run
      # Start a listener on the UDP socket
      EM.open_datagram_socket(config[:statsd_rcv_addr], config[:statsd_rcv_port], StatsdReceiverCounter, config, logger)
    end

  end


  module StatsdReceiverCounter
    attr_accessor :counters
    attr_accessor :timers
    attr_reader   :config
    attr_reader   :logger

    # set up timers to flush stats to graphite, and to log debugging info
    def initialize config, logger
      @config = config
      @logger = logger
      self.counters = Hash.new{|h,k| h[k] = 0  }
      self.timers   = Hash.new{|h,k| h[k] = [] }

      EM.add_periodic_timer(config[:flush_interval]) do
        flush_metrics
      end

      if config[:debug]
        EM.add_periodic_timer(config[:debug_interval]) do
          logger.debug([ "Counters:", counters.to_json, "Timers:", timers.to_json ].join("\t"))
        end
      end
    end

    # triggered when UDP packed received.
    def receive_data msg
      logger.debug("rcvd\t#{msg}") if config[:dump_messages]
      key, *bits = msg.strip.split(':')
      key  = key.gsub(/\s+/, '_').gsub(/\//, '-').gsub(/[^a-zA-Z_\-0-9\.]/, '')
      bits = ["1"] if bits.empty?
      bits.each do |bit|
        num,type,rate = bit.split('|')
        case
        when type.to_s.strip == 'ms'
          timers[key] << num.to_f
        when type.to_s.strip == 'c'
          if (rate.to_s =~ /^@([\d\.]+)/) then rate = $1.to_f else rate = 1.0 ; end
          num = 1 if num.blank?
          counters[key] += ( num.to_i / rate )
        else
          logger.info("Bad line: #{bit}") ; next
        end
      end
    end

    def flush_metrics
      ts        = Time.now.utc.to_i
      metrics   = []
      num_stats = 0

      # assemble metrics from all counters
      counters.each do |key, val|
        adj_val = val.to_f / config[:flush_interval]
        metrics << ["stats.#{key}",        adj_val]
        metrics << ["stats_counts.#{key}", val.to_i]
        #
        counters[key] = 0
        num_stats += 1
      end

      # assemble metrics from all timers
      timers.each do |key, timings|
        next if timings.blank?
        min, mean, max_at_threshold, max, count = timing_stats(timings)
        #
        metrics << ["stats.timers.#{key}.mean", mean]
        metrics << ["stats.timers.#{key}.upper", max]
        metrics << ["stats.timers.#{key}.upper_#{config[:percent_threshold]}", max_at_threshold]
        metrics << ["stats.timers.#{key}.lower", min]
        metrics << ["stats.timers.#{key}.count", count]
        #
        timers[key] = []
        num_stats += 1
      end

      # assemble metric showing number of metrics
      metrics << ["statsd.numStats", num_stats]
      
      # send them to graphite
      send_metrics(metrics, ts)
    end

    def timing_stats(timings)
      timings.sort!
      count = timings.length
      min   = timings.first
      max   = timings.last
      if count > 1
        num_in_threshold = count - (count * (100.0 - config[:percent_threshold]) / 100.0).round
        timings = timings[0 .. (num_in_threshold - 1)]
        max_at_threshold = timings.last
        mean = timings.sum / timings.length
      else
        max_at_threshold = max
        mean = min
      end
      [min, mean, max_at_threshold, max, count]
    end

  protected

    # Dispatch a set of metrics to graphite
    #
    # @param metrics [Array]   Array of tuples [name, value] to send to graphite
    # @param ts      [Integer] Timestamp for metrics
    def send_metrics(metrics, ts)
      metrics_message = metrics.map{|k,v| [k, v, ts].join(" ") }
      retried = false
      begin
        graphite_socket.write(metrics_message.join("\n"))
      rescue Errno::EPIPE, Errno::ECONNREFUSED => boom
        @graphite_socket = nil
        unless retried then retried = true; retry ; end
	logger.error("failed to save stats\t#{boom.class}\t#{boom}\t#{metrics_message.join("\t")}")
      end
    end

    # Reusable socket for talking to graphite
    def graphite_socket
      if @graphite_socket.nil? || @graphite_socket.closed?
        @graphite_socket = TCPSocket.new(config[:graphite_host], config[:graphite_port])
      end
      @graphite_socket
    end

  end
end
