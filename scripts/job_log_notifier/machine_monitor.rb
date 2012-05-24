#!/usr/bin/env ruby

require 'thread'
require 'socket'
require 'scanf'
require 'json'

# This script must be run in ruby, not jruby. Jruby's IO
# implementation is horribly broken.

module Vayacondios

  DEFAULT_STAT_SERVER_PORT = 13622

  module StatServer
    def self.serve_stats port = DEFAULT_STAT_SERVER_PORT
      queues = StatsQueues.new

      t = new_thread(queues, port) {|*a| accept_connections *a}
      t.run

      loop do
        stats_entry = {}

        # Grab the stats!
        # ifstat's delay will function as our heartbeat timer.
        is, ignore, rw = `ifstat 1 1`.split("\n").map(&:split)
        headers, *disks = `iostat -x`.split("\n")[5..-1].map(&:split)
        cpu, mem, swap, proc_headers, *procs = `top -b -n 1`.
          split("\n").map(&:strip).select{|x| not x.empty?}[2..-1]

        # Queue the stats up for listeners.
        queues.push \
        :net => is.zip(rw.each_slice(2).map{|r,w| {:r => r, :w => w}}).mkhash,
        :disk => disks.map{|d| [d.first, headers.zip(d).mkhash]}.mkhash,
        :cpu => split_top_stats(cpu),
        :mem => split_top_stats(mem),
        :swap => split_top_stats(swap)

      end
    end

    private

    def self.split_top_stats line
      line.split(':', 2).last.split(',').map(&:strip).map do |stat|
        stat.scanf("%f%*c%s").reverse
      end.mkhash
    end

    class ::Array
      def mkhash
        self.inject({}) {|h, item| h.merge item.first => item.last}
      end
    end

    def self.accept_connections queues, port
      puts port
      new_thread do
        Socket.tcp_server_loop port do |sock, client_addrinfo|
          new_thread sock, q = queues.create do |*a|
            begin
              handle_connection *a
            ensure
              queues.destroy q
            end
          end
        end
      end
    end

    def self.handle_connection client, stats_queue
      loop do
        begin
          client.puts JSON.generate stats_queue.pop
        rescue Errno::EPIPE
          break
        end
      end
    end

    def self.new_thread *args, &blk
      Thread.new *args do
        begin
          yield *args
        rescue Exception => e
          STDERR.write "#{e}\n#{e.backtrace.join "\n"}\n"
        end
      end
    end

    #
    # provides thread-safe access to queues through which stats will
    # be pushed
    #
    class StatsQueues
      def initialize
        @queues = []
        @lock = Mutex.new
      end

      def push val 
        @lock.synchronize { @queues.each {|q| q.push val} }
      end

      def create
        @lock.synchronize { (@queues << Queue.new).last }
      end

      def destroy queue
        @lock.synchronize { @queues.delete queue }
      end
    end
  end
end
