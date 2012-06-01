#!/usr/bin/env ruby

require_relative 'configure'
require 'thread'
require 'socket'
require 'scanf'
require 'json'
require 'mongo'

module Vayacondios

  class StatServer

    include Configurable

    def initialize
      unless get_conf[MONGO_IP]
        raise "The IP address of the mongo server must be set!"
      end

      logger.info "Connecting to Mongo server at ip #{get_conf[MONGO_IP]}"
      conn = Mongo::Connection.new get_conf[MONGO_IP]
      logger.debug "Getting job database #{get_conf[MONGO_JOBS_DB]}"
      @db = conn[get_conf[MONGO_JOBS_DB]]
    end

    def run
      logger.debug "Waiting for hadoop monitor to create the event collection."
      sleep get_conf[SLEEP_SECONDS] until
        @db.collection_names.index get_conf[MONGO_JOB_EVENTS_COLLECTION]

      job_events = @db[get_conf[MONGO_JOB_EVENTS_COLLECTION]]

      logger.debug "Got the event collection. Creating machine stats collection."
      machine_stats = @db.
        create_collection(get_conf[MONGO_MACHINE_STATS_COLLECTION],
                          :capped => true,
                          :size => get_conf[MACHINE_STATS_SIZE])

      logger.debug "Querying job_events until we see an insertion."
      # Keep querying the job_events collection until there's an
      # event. Don't just use the cursor from .find without checking,
      # because if hadoop_monitor inserts an event into an empty
      # database, this cursor will no longer work, even if it's
      # tailable. not quite sure why Mongo does it that way.
      events = job_events.find
      events.add_option 0x02 # tailable
      until events.has_next?
        sleep get_conf[SLEEP_SECONDS]
        events = job_events.find
        events.add_option 0x02 # tailable
      end

      logger.debug "Priming main event loop. Waiting to see if the cluster is working."

      # Get up-to-date on the state of the cluster. assume quiet to start.
      cluster_working = self.class.next_state(events, false, get_conf[EVENT])

      # main loop
      loop do
        
        logger.debug "In main event loop. Waiting to see if the cluster is working."

        # Get up-to-date on the state of the cluster.
        cluster_working = self.class.next_state(events, cluster_working, get_conf[EVENT])

        # Don't grab stats unless the cluster is working
        unless cluster_working
          sleep get_conf[SLEEP_SECONDS]
          next
        end

        logger.debug "Grabbing stats and pushing them into the collection."

        # Grab the stats!
        # ifstat's delay will function as our heartbeat timer.
        is, ignore, rw = `ifstat 1 1`.split("\n").map(&:split)
        headers, *disks = `iostat -x`.split("\n")[5..-1].map(&:split)
        cpu, mem, swap, proc_headers, *procs = `top -b -n 1`.
          split("\n").map(&:strip).select{|x| not x.empty?}[2..-1]

        # Write the stats into the mongo collection.
        machine_stats.insert(
          :net => Hash[is.zip(rw.each_slice(2).map{|r,w| {:r => r, :w => w}})],
          :disk => Hash[disks.map{|d| [d.first, Hash[headers.zip(d)]]}],
          :cpu => self.class.split_top_stats(cpu),
          :mem => self.class.split_top_stats(mem),
          :swap => self.class.split_top_stats(swap))
      end
    end

  private

    def self.split_top_stats line
      Hash[line.split(':', 2).last.split(',').map(&:strip).map do |stat|
             stat.scanf("%f%*c%s").reverse
           end]
    end

    def self.next_state events_cursor, current_state, event_attr_name
      while current_event = events_cursor.next
        current_state = case current_event[event_attr_name]
                        when CLUSTER_WORKING then true
                        when CLUSTER_QUIET then false
                        else current_state
                        end
      end
      current_state
    end
  end
end

Vayacondios::StatServer.new.run
