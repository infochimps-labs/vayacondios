#!/usr/bin/env ruby

require_relative 'configure'
require 'thread'
require 'socket'
require 'scanf'
require 'json'
require 'mongo'

# This script must be run in ruby, not jruby. Jruby's IO
# implementation is horribly broken.

module Vayacondios

  module StatServer

    include Configurable

    def self.serve_stats port = nil
      conf = Configuration.new.conf
      # TODO: get master host and connect to its db
      conn = Mongo::Connection.new
      db = conn[conf[MONGO_JOBS_DB]]

      sleep conf[SLEEP_SECONDS] until
        db.collection_names.index conf[MONGO_JOB_EVENTS_COLLECTION]

      job_events = db[conf[MONGO_JOB_EVENTS_COLLECTION]]

      machine_stats = db.create_collection(conf[MONGO_MACHINE_STATS_COLLECTION],
                                           :capped => true,
                                           :size => conf[MACHINE_STATS_SIZE])

      # Look for events that start after
      job_events.insert :event => "ignore", :time => 0
      events = job_events.find :_id => {"$gt" => BSON::ObjectId.new}
      events.add_option 0x02 # tailable

      cluster_working = false

      loop do

        # Change state if necessary.
        current_event = events.next || {}
        cluster_working = case current_event[EVENT]
                          when CLUSTER_WORKING then true
                          when CLUSTER_QUIET then false
                          else cluster_working
                          end

        unless cluster_working
          sleep conf[SLEEP_SECONDS]
          next
        end

        # Grab the stats!
        # ifstat's delay will function as our heartbeat timer.
        is, ignore, rw = `ifstat 1 1`.split("\n").map(&:split)
        headers, *disks = `iostat -x`.split("\n")[5..-1].map(&:split)
        cpu, mem, swap, proc_headers, *procs = `top -b -n 1`.
          split("\n").map(&:strip).select{|x| not x.empty?}[2..-1]

        # Queue the stats up for listeners.
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
  end
end

Vayacondios::StatServer.serve_stats
