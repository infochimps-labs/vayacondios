#!/usr/bin/env ruby

require_relative 'configure'
require 'thread'
require 'socket'
require 'scanf'
require 'json'
require 'mongo'

module Vayacondios

  module StatServer

    include Configurable

    def self.serve_stats port = nil
      vconf = Configuration.new.conf
      unless hadoop_monitor_ip = vconf.get_conf[HADOOP_MONITOR_NODE]
        raise "The IP address of the hadoop monitor node must be set!"
      end

      conn = Mongo::Connection.new vconf.get_conf[HADOOP_MONITOR_NODE]
      db = conn[vconf.get_conf[MONGO_JOBS_DB]]

      # Wait until the hadoop monitor creates the event collection.
      sleep vconf.get_conf[SLEEP_SECONDS] until
        db.collection_names.index vconf.get_conf[MONGO_JOB_EVENTS_COLLECTION]

      job_events = db[vconf.get_conf[MONGO_JOB_EVENTS_COLLECTION]]

      machine_stats = db.
        create_collection(vconf.get_conf[MONGO_MACHINE_STATS_COLLECTION],
                          :capped => true,
                          :size => vconf.get_conf[MACHINE_STATS_SIZE])

      events = job_events.find
      events.add_option 0x02 # tailable

      # Get up-to-date on the state of the cluster. assume quiet to start.
      cluster_working = next_state events, false

      # main loop
      loop do

        # Stay asleep until there is an event to parse.
        sleep vconf.get_conf[SLEEP_SECONDS] until current_event = events.next

        # Get up-to-date on the state of the cluster.
        cluster_working = next_state events, cluster_working

        # Don't grab stats unless the cluster is working
        next unless cluster_working

        # Grab the stats!
        # ifstat's delay will function as our heartbeat timer.
        is, ignore, rw = `ifstat 1 1`.split("\n").map(&:split)
        headers, *disks = `iostat -x`.split("\n")[5..-1].map(&:split)
        cpu, mem, swap, proc_headers, *procs = `top -b -n 1`.
          split("\n").map(&:strip).select{|x| not x.empty?}[2..-1]

        # Write the stats into the mongo collection.
        machine_stats.insert \
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

    def self.next_state events_cursor, current_state
      while current_event = events_cursor.next
        current_state = case current_event[vconf.get_conf[EVENT]]
                        when CLUSTER_WORKING then true
                        when CLUSTER_QUIET then false
                        else current_state
                        end
      end
      current_state
    end
  end
end

Vayacondios::StatServer.serve_stats
