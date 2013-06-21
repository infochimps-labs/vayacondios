require 'configliere'
require 'chronic_duration'
ChronicDuration.raise_exceptions = true
class Vayacondios

  # Implements a program `vcd-clean` which makes it easy to clean out
  # old events from a MongoDB database that's been supporting a
  # running Vayacondios server for some time.
  #
  # All events for a given organization and topic are stored by the
  # Vayacondios server in the same MongoDB collection.
  #
  # No attempt is made at providing functionality for cleaning out
  # stale hashes.
  #
  # This cleaner connects directly to MongoDB.  It does **not** use
  # the Vayacondios server API to perform its deletes.
  #
  # @attr [Mongo::Connection] mongo a connection to the MongoDB server
  # @attr [Mongo::Database] database the MongoDB database
  # @attr [Time] upto the boundary for how recent an event has to be to avoid getting cleaned
  # @attr [Time] from the boundary for how old an event has to be to avoid getting cleaned
  class Cleaner

    attr_accessor :mongo
    attr_accessor :database
    attr_accessor :upto
    attr_accessor :from

    # A class to wrap errors arising from interpreting command-line
    # options or interacting with MongoDB.
    Error = Class.new(StandardError)

    # Returns the settings for the `vcd-clean` program.
    #
    # @return [Configliere::Param]
    def settings
      @settings ||= Configliere::Param.new.tap do |s|
        s.use :commandline
        def s.usage
          "usage: vcd-clean [ --param=val|--param|-p val|-p ]"
        end
        s.description = <<DESCRIPTION
Cleans events from the MongoDB database backing a Vayacondios server.

A single running Vayacondios server reads and writes all its data to
and from a single database on a MongoDB server(s).  By default,
vcd-clean targets the "vayacondios_development" database on a local
MongoDB server running on the usual port (27017).  You can change this
behavior with the --host, --port, and --database options.

Clean all events with timestamps upto than some fixed time

  $ vcd-clean --upto='2013-06-18 Tue 00:00:00 -0500'

or clean everything up to the present moment

  $ vcd-clean --upto=now

or from than 1 hour before the current time

  $ vcd-clean --from=1hr

or within a fixed window

  $ vcd-clean --from='2013-06-18 Tue 00:00:00 -0500' --upto=now

By default the collections holding data for events of all topics will
be affected.  You can change the set of collections affected with a
regular expression

  $ vcd-clean --matching='my_topic\.events$' --upto='2013-06-18 Tue 00:00:00 -0500'

Vayacondios stores events within the organization "coca_cola" on the
topic "taste_tests" in the collection "coca_cola.taste_tests.events".

Passing the --dry_run option will make vcd-clean print out a count for
each collection it would have affected and how many records would have
been removed.

Reads configuration files at /etc/vayacondios/vayacondios.yml and
~/.vayacondios.yml.
DESCRIPTION

        s.define :host,     description: "MongoDB host",     default: "localhost", required: true
        s.define :port,     description: "MongoDB port",     default: 27017, type: Integer, required: true
        s.define :database, description: "MongoDB database", default: 'vayacondios_development', required: true
        
        s.define :matching, description: "Regular expression matching the names of collections to clean", type: Regexp, default: /^.*\.events$/, required: true
        
        s.define :upto, description: "Delete all events upto than this time"
        s.define :from, description: "Delete all events from than this time"
        
        s.define :dry_run, description: "Don't delete any events, just show what would be done", type: :boolean, default: false
      end
    end

    # Run a new instance of the `vcd-cleaner` program.
    #
    # Instantiates a new instance of Cleaner and take it through its
    # lifecycle.
    #
    # @raise [SystemExit] when execution stops either because the
    #   database has been cleaned or an error has occurred
    def self.run
      cleaner = new
      begin
        cleaner.boot
        cleaner.validate        
        cleaner.connect
        cleaner.clean
      rescue Error => e
        $stderr.puts e.message
        exit(1)
      end
    end
    
    # Boot up, reading config files at
    # /etc/vayacondios/vayacondios.yml and `/.vayacondios.yml`.
    def boot
      settings.read("/etc/vayacondios/vayacondios.yml")    if File.exist?("/etc/vayacondios/vayacondios.yml")
      settings.read(File.expand_path("~/.vayacondios.yml")) if ENV["HOME"] && File.exist?(File.expand_path("~/.vayacondios.yml"))
      settings.resolve!
      self.upto = parse_time(settings[:upto])
      self.from = parse_time(settings[:from])
    end

    # Validate that the provided timeframe is sensible.
    #
    # @raise [Error] if neither of `--upto` nor `--from` was given
    # @raise [Error] if either of  `--upto` or `--from` was given and couldn't be parsed
    # @raise [Error] if both of  `--upto` and `--from` were given and upto is earlier than from
    def validate
      raise Error.new("Must provide either/both of the --from or --upto options") unless upto || from
      raise Error.new("--from option must be earlier in time than --upto option") if (upto && from) && (upto < from)
    end

    # Connect to the MongoDB server containing the database to clean.
    def connect
      $stderr.puts "Connecting to MongoDB at #{settings[:host]}:#{settings[:port]}/#{settings[:database]}"
      require 'mongo'
      self.mongo    = Mongo::Connection.new(settings[:host], settings[:port])
      self.database = self.mongo.db(settings[:database])
    end

    # Clean the database and print out a list of document counts by
    # collection.
    def clean
      $stderr.puts(timeframe_message)
      matching_collections.each do |collection|
        count = clean_collection(collection)
        puts [count, collection].map(&:to_s).join("\t")
      end
    end

    private


    # Parses a given string into a time.
    #
    # Accepts a variety of formatted times.
    #
    # @example The current time
    #
    #   parse_time('now')
    #
    # @example A specific time
    #
    #   parse_time('2013-06-20 Thu 15:03:00 -0500')
    #
    # @example Some amount of time before present
    #
    #   parse_time('4h30m')
    #
    # @param [String] string the time string to parse
    # @return [Time] the parsed time in UTC
    #
    # @raise [Error] if the `string` could not be parsed as a time or
    #   duration
    def parse_time string
      return Time.now.utc if string == 'now'
      begin
        duration = ChronicDuration.parse(string)
        return (Time.now - duration).utc
      rescue ChronicDuration::DurationParseError => e
        begin
          return Time.parse(string).utc
        rescue ArgumentError => e
          raise Error.new("Couldn't parse time: <#{string}>")
        end
      end
    end
    
    # Return collections in the MongoDB database which match the
    # arguments passed to this Cleaner.
    #
    # @return [Array<String>] the names of the collections which match
    def matching_collections
      database.collection_names.find_all do |collection_name|
        collection_name =~ settings[:matching]
      end
    end
    
    # Return a message describing the operation to occur and the
    # timeframe over which it will occur.
    #
    # @return [String]
    def timeframe_message
      "#{settings[:dry_run] ? 'Will remove' : 'Removing'} all events " + 
        case
        when upto && from
          "#{upto} - #{from}"
        when upto
          "before #{upto}"
        when from
          "after #{from}"
        end
    end

    # Clean the collection.
    #
    # If in "dry-run" mode then will just count the number of matching
    # documents in the collection and return that count.
    #
    # Otherwise, will remove those documents and return the count of
    # how many were removed.
    #
    # @param [String] collection the name of the collection to clean 
    # @return [Integer] the number of records cleaned or that would have cleaned (if in "dry-run" mode)
    def clean_collection collection
      if settings[:dry_run]
        count_stale_records(collection)
      else
        remove_stale_records(collection)
      end
    end

    # Return the number of stale records in the given collection.
    #
    # @param [String] collection
    # @return [Integer]
    # @see #query
    def count_stale_records collection
      database.collection(collection).count(query)
    end

    # Remove stale records from the given collection.
    #
    # @param [String] collection
    # @return [Integer] the number of records that were removed
    # @see #query
    def remove_stale_records collection
      result = database.collection(collection).remove(query)
      if result['err']
        $stderr.puts "Error cleaning #{collection}: #{result['err']}"
        '?'
      else
        result['n']
      end
    end

    # The query which defines, for any collection, which records are
    # stale and should be cleaned.
    #
    # Can be applied both in a #count as well as a #remove so it
    # ensures consistency when flipping "dry-run" mode on and off.
    #
    # @return [Hash]
    # @see #count_stale_records
    # @see #remove_stale_records
    def query
      {
        t: {}.tap do |constraints|
          constraints[:$lte] = upto if upto
          constraints[:$gte] = from if from
        end
      }
    end

  end
end
