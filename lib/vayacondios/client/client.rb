class Vayacondios

  # An abstract implementation of a Vayacondios client.
  #
  # Defines methods for announcing events and setting/getting/deleting
  # stashes.
  #
  # @example Announce an event on the topic `intrusions`
  #
  #   Vayacondios::Client.new(organization: 'InfoSec').announce('intrusions', ip: '10.123.123.123', priority: 3, type: 'ssh')
  #
  # @example Merge stash for topic `firewall` and ID `webservers`
  #
  #   Vayacondios::Client.new(organization: 'InfoSec').set('firewall', 'webservers', internet: {port: 80, range: '*'}, blacklisted: ['10.123.123.123'])
  #
  # @example Retrieve stash for topic `firewall` and ID `webservers`
  #
  #   Vayacondios::Client.new(organization: 'InfoSec').get('firewall', 'webservers')
  #
  # @example Delete stash for topic `firewall` and ID `webservers`
  #
  #   Vayacondios::Client.new(organization: 'InfoSec').delete('firewall', 'webservers')
  #
  # The client can operate in "dry run" mode in which it will simply
  # log all the requests it *would* have made.  The client's log can
  # be customized.
  #
  # @abstract For each API method (`announce`, `get`, `set`, &c.) a
  # concrete subclass should implement the corresponding `perform_`
  # method (`perform_announce`, `perform_get`, `perform_set`, &c.)
  class Client

    # The version of the Vayacondios API this client is using.
    VERSION = 'v2'

    # An error to raise on bad requests.
    Error = Class.new(StandardError)

    # The organization this client is fixed to.
    attr_accessor :organization

    # Options this client was instantiated with.
    attr_accessor :options

    # Create a new Client.
    #
    # @example Creating a new client that will read and write data for the `Example` organization.
    #
    #   client = Vayacondios::Client.new(organization: 'Example')
    #
    # Will raise an error if instantiated without an organization.
    #
    # The client will create its own logger but you can override this
    # with another Logger (or similar) instance.
    #
    # @example Creating a new client with a custom logger
    #
    #   client = Vayacondios::Client.new(organization: 'Example', log: custom_logger)
    #
    # @param [Hash] options
    # @option options [Logger, #info, #debug, #warn, #error] :log a logger to override the default logger
    # @option options [String] :log_file ($stderr) path to this client's log.  Set to '-' to use $stdout.
    # @option options [String] :log_level ('info') the level for the log
    # @option options [String] :organization the organization to fix this client to
    #
    # @see #log
    def initialize options={}
      self.options      = options
      self.log          = options[:log] if options[:log]
      self.organization = (options[:organization] or raise Error.new("No organization was specified")).to_s
    end

    # Is this client in dry run mode?
    #
    # While in dry run mode, the client will not make any requests of
    # the server.  It will instead log each one explicitly.
    #
    # @return [true, false]
    def dry_run?
      !! options[:dry_run]
    end

    #
    # == API ==
    #


    # Announce a new event.
    #
    # A topic is required when announcing an event.
    #
    # If you don't specify an ID for the event, one will be generated
    # by the server and returned to you in the response.
    # 
    # Similarly, if you don't specify the time of the event, the
    # current time (upon arrival at the server) will be used.  You can
    # set the time of the event explicitly by including the `time` key
    # in your event data.
    #
    # Setting the time and the ID are done in different places because
    # the ID is related to the *label* (equivalently the *routing*) of
    # the event while the time is related to the *data* of the event.
    #
    # If this client is in dry run mode the request will be logged
    # instead of sent.
    #
    # @example Announce an SSH intrusion event in your network on topic `intrusions`
    #
    #   client.announce('intrusions', ip: '10.123.123.123', priority: 3, type: 'ssh')
    #   #=> {"id"=>"51aae2f181bdb31d10000007", "time"=>"2013-06-02 01:15:13 -0500", "ip"=>"10.123.123.123", "priority"=>"3", "type"=>"ssh"}
    #
    # @example Same example but using a single Hash argument instead
    # 
    #   client.announce({
    #     topic: 'intrusions',
    #     event: {ip: '10.123.123.123', priority: 3, type: 'ssh'}
    #   })
    #   #=> {"id"=>"51aae2f181bdb31d10000007", "time"=>"2013-06-02 01:15:13 -0500", "ip"=>"10.123.123.123", "priority"=>"3", "type"=>"ssh"}
    #
    # @example Announce a new build of your project on topic `builds` with ID given by the SHA1 of your commit.
    #
    #   client.announce('builds', { name: 'Little Stinker', version: '1.2.3', status: 'success', duration: 183 }, '13fe3ff5f13c6b0394cc22501a9617cfe2445c63')
    #   #=> {"id"=>"13fe3ff5f13c6b0394cc22501a9617cfe2445c63", "time"=>"2013-06-02 01:15:13 -0500", "name"=>"Little Stinker", "version"=>"1.2.3", "status"=>"success", "duration"=>183}
    #
    # @example Same example but using a single Hash argument instead
    #
    #   client.announce({
    #     topic: 'builds',
    #     id:    '13fe3ff5f13c6b0394cc22501a9617cfe2445c63',
    #     event: {
    #       name:     'Little Stinker',
    #       version:  '1.2.3',
    #       status:   'success',
    #       duration: 183,
    #     }
    #   })
    #   #=> {"id"=>"13fe3ff5f13c6b0394cc22501a9617cfe2445c63", "time"=>"2013-06-02 01:15:13 -0500", "name"=>"Little Stinker", "version"=>"1.2.3", "status"=>"success", "duration"=>183}
    #
    # @example Setting an explicit time for an event
    #
    #   client.announce('intrusions', ip: '10.123.123.123', priority: 3, type: 'ssh', time: "2013-06-02 00:00:00 -0000")
    #   #=> {"id"=>"51aae2f181bdb31d10000007", "time"=>"2013-06-02 00:00:00 -0000", "ip"=>"10.123.123.123", "priority"=>"3", "type"=>"ssh"}
    #
    # @example Same example but using a single Hash argument instead
    #
    #   client.announce({
    #     topic: 'intrusions',
    #     event: {
    #       ip:       '10.123.123.123',
    #       priority: 3,
    #       type:     'ssh',
    #       time:     "2013-06-02 00:00:00 -0000"
    #     }
    #   })
    #   #=> {"id"=>"51aae2f181bdb31d10000007", "time"=>"2013-06-02 00:00:00 -0000", "ip"=>"10.123.123.123", "priority"=>"3", "type"=>"ssh"}
    #
    # @return [Hash] the event returned by the server in acknowledgement
    #
    # @overload announce(topic, event, id=nil)
    #   Call with explicit arguments
    #   @param [String] topic the topic to announce on
    #   @param [Hash] event the event to announce
    #   @param [String, nil] id the optional ID for the event
    #
    # @overload announce(options={})
    #   Call with a single Hash argument
    #   @param [Hash] options
    #   @option options [String] :topic the topic of the event (required)
    #   @option options [String] :event the body of the event (required)
    #   @option options [String] :id the ID of the event (optional)
    def announce *args
      topic, event, id = extract_topic_event_and_id(*args)
      if dry_run?
        msg  = "Announcing <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{event.inspect}"
        log.debug(msg)
        nil
      else
        perform_announce(topic, event, id)
      end
    end

    # Search for events matching some query.
    #
    # A topic is required when searching for events.
    #
    # The default search behavior implemented by Vayacondios server is
    # to return up to 50 events from the last hour on the given topic
    # sorted by timestamp.
    #
    # The events which match, number of events returned, the time
    # period, and sorting behavior can all be changed.
    #
    # The set of fields returned in each event can also be specified.
    # Default behavior is to return all fields.
    #
    # @example Retrieve recent events on the `intrusions` topic.
    #
    #   client.events('intrusions')
    #
    # Each event must match each key/value pair in the `query`, with
    # dots used to indicate nested fields.
    #
    # @example Retrieve recent intrusion events which have the field
    # `type` equal to "ssh" and have a field `data_center` which is a
    # Hash containing a field `name` equal to "Phoenix"
    #
    #  client.events('intrusions', type: 'ssh', 'data_center.name' => 'Phoenix')
    #
    # There are many more options, too:
    #
    # @example Request more than 50 events
    #
    #   client.events('intrusions', limit: 100)
    #
    # @example Specify a different time period
    # 
    #   client.events('intrusions', time: {from: (Time.now - 1.day), upto: (Time.now - 1.hour)})
    #
    # @example Return only the `request.ip` and `port` of the event
    # 
    #   client.events('intrusions', fields: ['request.ip','port'])
    #
    # @example Sort the returned events by the IP of the requestor in ascending order instead of the timestamp.
    #
    #   client.events('intrustions', sort: ['request.ip', 'ascending'])
    #
    # @example Above examples but combined into a single Hash argument
    #
    #   client.events({
    #     topic:  'intrusions',
    #     query:  {
    #       limit: 100,
    #       from: (Time.now - 1.day),
    #       upto: (Time.now - 1.hour),
    #       fields: ['request.ip', 'port'],
    #       sort:   ['request.ip', 'ascending'],
    #       type: 'ssh',
    #       'data_centers.name' => 'Phoenix',
    #     }
    #   })
    #
    # @overload events(topic, query={})
    #   Call with explicit arguments
    #   @param [String] topic the topic to search
    #   @param[Hash] query the search query
    #   @option query [Integer] :limit (50) the maximum number of events to return
    #   @option query [Time] :from (an hour ago) the earliest time an event can occur
    #   @option query [Time] :upto (present) the latest time an event can occur
    #   @option query [Array<String>] :fields (all fields) the fields of the event to return
    #   @option query [Array<Array>] :sort array of [field, direction] pairs to sort by
    #
    # @overload events(options={})
    #   Call witha  single Hash argument
    #   @param [Hash] options
    #   @option options [String] :topic the topic to search
    #   @option options [Hash] :query the search query
    #
    # @return the matching events
    def events *args
      topic, query = extract_topic_and_query(*args)
      if dry_run?
        log.debug("Searching events/<#{topic}>: #{query.inspect}")
        nil
      else
        perform_events(topic, query)
      end
    end

    # Retrieve a stash.
    #
    # Requires a topic.  If an ID is given, will return the stash for
    # the ID within the topic, otherwise the stash for the entire
    # topic.
    #
    # Will return whatever value is stored at the corresponding topic
    # (and ID) or `nil` if none is found.
    #
    # If the client is in dry run mode, the request will be logged
    # instead of sent and `nil` will be returned.
    #
    # @example Retrieve a list of firewall rules on the topic `firewall` under the ID `webservers`
    #
    #   client.get('firewall', 'webservers')
    #
    # @example Same example but using a single Hash argument
    #
    #   client.get(topic: 'firewall', id: 'webservers')
    #
    # @example Retrieve a list of all firewall rules on the topic `firewall`
    #
    #   client.get('firewall')
    #
    # @example Same example but using a single Hash argument
    #
    #   client.get(topic: 'firewall')
    #
    # @return [Object] the value stored fore the given `topic` and `id` or `nil` if none is found
    #
    # @overload get(topic, id=nil)
    #   Call with explicit arguments
    #   @param [String] topic the topic to get (required)
    #   @param [String] id the ID to get (can be `nil`)
    #
    # @overload get(options={})
    #   Call with a single Hash argument
    #   @param [Hash] options
    #   @option options [String] :topic the topic to get (required)
    #   @option options [String] :id the ID to get (optional)
    def get *args
      topic, id = extract_topic_and_id(*args)
      if dry_run?
        msg  = "Getting <#{topic}>"
        msg += "/<#{id}>" if id
        log.debug(msg)
        nil
      else
        perform_get(topic, id)
      end
    end

    # Search for stashes matching some query.
    #
    # The default search behavior is to return the first 50 stashes
    # sorted by topic in ascending order.
    #
    # The stashes which match, number of stashes returned, and the
    # sorting behavior can all be changed.
    #
    # @example Retrieve the first 50 stashes
    #
    #   client.stashes()
    #
    # Each stash must match each key/value pair in the `query`, with
    # dots used to indicated nested fields.
    #
    # @example Retrieve stashes which have the field `type` equal to
    # "Server" and the have a field `cloud` which is a Hash containing
    # a field `provider` equal to "ec2"
    #
    #   client.stashes(type: "Server", "cloud.provider" => "ec2")
    #
    # There are many more options, too:
    #
    # @example Retrieve the first 100 stashes
    #
    #   client.stashes(limit: 100)
    #
    # @example Sort the returned stashes by the value of their
    # `error_count` field in descending order
    #
    #   client.stashes(sort: ['error_count', 'descending'])
    #
    # @example Above examples combined into a single Hash argument
    #
    #   client.stashes({
    #     limit: 100,
    #     sort:  ['error_count', 'descending'],
    #     type:  "Server",
    #     "cloud.provider" => "ec2",
    #   })
    #
    # @param [Hash] query the search query
    # @option query [Integer] :limit (50) the maximum number of stashes to return
    # @option query [Array<Array>] :sort array of [field, direction] pairs to sort by
    # @return the matching stashes
    def stashes query={}
      if dry_run?
        log.debug("Searching stashes: #{query.inspect}")
        nil
      else
        perform_stashes(query)
      end
    end
    
    # Set a stash by replacing it with the given value.
    #
    # A topic is required when setting a stash.
    #
    # If no ID is provided, the the given `value` must be a Hash.  If
    # an ID is provided then the given value can be of any
    # JSON-serializable type.
    #
    # Whatever is currently set for this topic (and ID) will be
    # overwritten.
    #
    # @example Replace existing firewall rules with new ones for the topic `firewall` and ID `webservers`
    #
    #   client.set!('firewall', 'webservers', internet: {port: 80, range: '*'}, blacklisted: ['10.123.123.123'])
    #
    # @example Same example but with a single Hash argument
    #
    #   client.set!({
    #     topic:    'firewall',
    #     id:       'webservers',
    #     value: {
    #       internet:    { port: 80, range: '*'},
    #       blacklisted: ['10.123.123.123']
    #     }
    #   })
    #
    # @example Set the current server count to `44`.
    #
    #   client.set!('servers', 'count', 44)
    #
    # @example Same example but with a single Hash argument
    #
    #   client.set!(topic: 'servers', id: 'count', value: 44)
    #
    # @example Replace all existing firewall rules for all IDs
    #
    #   client.set!('firewall', {
    #     webservers: {
    #       internet:    {port: 80, range: '*'},
    #       blacklisted: ['10.123.123.123']
    #     },
    #     datanodes: {
    #       internet: {port: 6383, range: '10.*'}
    #     }
    #   })
    #
    # @example Same example but with a single Hash argument
    #
    #   client.set!({
    #     topic: 'firewall',
    #     value: {
    #       webservers: {
    #         internet:    {port: 80, range: '*'},
    #         blacklisted: ['10.123.123.123']
    #       },
    #       datanodes: {
    #         internet: {port: 6383, range: '10.*'}
    #       }
    #     }
    #   })
    #
    # @return The value received by the server which was sent (or `nil` if in dry run mode)
    #
    # @overload set!(topic, id, value)
    #   Call with explicit arguments
    #   @param [String] topic the topic to set (required)
    #   @param [String] id the ID to set (can be `nil`)
    #   @param [Object] value the value to set.  Must be a Hash if `id` is `nil`
    #
    # @overload set!(options={})
    #   Call with a single Hash argument
    #   @param [Hash] options
    #   @option options [String] :topic the topic to set (required)
    #   @option options [String] :id the ID to set (optional)
    #   @option options [Object] :value the value to set.  Must be a Hash if no ID is provided
    def set! *args
      topic, id, value = extract_topic_id_and_value(*args)
      if dry_run?
        msg  = "Replacing <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{value.inspect}"
        log.debug(msg)
        nil
      else
        perform_set!(topic, id, value)
      end
    end

    # Set a stash by merging the given value into it.
    #
    # A topic is required when setting a stash.
    #
    # If no ID is provided, the the given `value` must be a Hash.  If
    # an ID is provided then the given value can be of any
    # JSON-serializable type.
    #
    # Whatever value is provided will be merged with the existing
    # value in a type-aware way: Hashes will be merged, Arrays &
    # Strings will be concatenated, Numeric types will be incremented.
    #
    # @example Set a new firewall rule on the topic `firewall` for the ID `webservers`
    #
    #   client.set('firewall', 'webservers', internet: {port: 80, range: '*'})
    #
    # @example Same example but with a single Hash argument
    #
    #   client.set({
    #     topic: 'firewall',
    #     id:    'webservers',
    #     value: {
    #       internet: { port: 80, range: '*' }
    #     }
    #   })
    #
    # @example Increment the current server count by 2
    #
    #   client.set('servers', 'count', 2)
    #
    # @example Same example but with a single Hash argument
    #
    #   client.set(topic: 'servers', id: 'count', value: 2)
    #
    # @example Merge two new firewall rules into an existing set of rules
    #
    #   client.set('firewall', {
    #     webservers: {
    #       internet:    {port: 80, range: '*'},
    #       blacklisted: ['10.123.123.123']
    #     },
    #     datanodes: {
    #       internet: {port: 6383, range: '10.*'}
    #     }
    #   })
    #
    # @example Same example but with a single Hash argument
    #
    #   client.set({
    #     topic: 'firewall',
    #     value: {
    #       webservers: {
    #         internet:    {port: 80, range: '*'},
    #         blacklisted: ['10.123.123.123']
    #       },
    #       datanodes: {
    #         internet: {port: 6383, range: '10.*'}
    #       }
    #     }
    #   })
    #   
    # @return The value received by the server which was sent (or `nil` if in dry run mode)
    #
    # @overload set(topic, id, value)
    #   Call with explicit arguments
    #   @param [String] topic the topic to set (required)
    #   @param [String] id the ID to set (can be `nil`)
    #   @param [Object] value the value to set.  Must be a Hash if `id` is `nil`
    #
    # @overload set(options={})
    #   Call with a single Hash argument
    #   @param [Hash] options
    #   @option options [String] :topic the topic to set (required)
    #   @option options [String] :id the ID to set (optional)
    #   @option options [Object] :value the value to set.  Must be a Hash if no ID is provided
    #
    # @see #increment
    def set *args
      topic, id, value = extract_topic_id_and_value(*args)
      if dry_run?
        msg  = "Merging <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{value.inspect}"
        log.debug(msg)
        nil
      else
        perform_set(topic, id, value)
      end
    end

    # An alias for the `set` method, used for readability when setting
    # numeric values.
    #
    # @example Increment the current server count by 2
    #
    #   client.increment('servers', 'count', 2)
    #
    # @see #set
    def increment *args
      set *args
    end

    # Delete a stash.
    #
    # Requires a topic.  If an ID is given, will delete the stash at
    # the given ID within the given topic, otherwise will delete the
    # entire topic.
    #
    # @example Delete the firewall rules for the 'webservers' ID
    #
    #   client.delete('firewall', 'webservers')
    #
    # @example Same example but with a single Hash argument
    #
    #   client.delete(topic: 'firewall', id: 'webservers')
    #
    # @example Delete all the firewall rules
    #
    #   client.delete('firewall')
    #
    # @example Same example but with a single Hash argument
    #
    #   client.delete(topic: 'firewall')
    #
    # @return [Hash] with the topic (and ID) of the deleted stash or `nil` if in dry run mode.
    #
    # @overload delete(topic, id=nil)
    #   Call with explicit arguments
    #   @param [String] topic the topic to delete (required)
    #   @param [String] id the ID to delete (can be `nil`)
    #
    # @overload delete(options={})
    #   Call with a single Hash argument
    #   @param [Hash] options
    #   @option options [String] :topic the topic to delete (required)
    #   @option options [String] :id the ID to delete (optional)
    def delete topic, id=nil
      if dry_run?
        msg  = "Deleting <#{topic}>"
        msg += "/<#{id}>" if id
        log.debug(msg)
        nil
      else
        perform_delete(topic, id)
      end
    end

    # Convert an object into a simple value that can be serialized and
    # sent to the server.
    #
    # Objects which define "standard" methods (`to_hash`, `to_a`, &c.)
    # will have those methods called to turn them into Hashes or
    # Arrays.
    #
    # In usual usage, this method is essentially just returning the
    # same object you probably called it with.
    #
    # @param [Object] obj the original object
    # @return [Object] the simplified document representing that object
    def to_document obj
      case
      # special behavior for VCD
      when obj.respond_to?(:to_vayacondios) then obj.to_vayacondios 
        
      # is it a Hash
      when obj.respond_to?(:to_wire)        then obj.to_wire        # support gorillib
      when obj.respond_to?(:to_hash)        then obj.to_hash        # support many things
      when obj.respond_to?(:to_h)           then obj.to_h           # new 2.0 convention

      # is it an Array
      when obj && obj.respond_to?(:to_a)    then obj.to_a           # longstanding convention

      # otherwise just keep it how it is
      else
        obj
      end
    end

    # The log this client will use.
    #
    # Defaults to writing to $stderr at INFO level.
    #
    # @return [Logger]
    #
    # @see #initialize
    def log
      return @log if @log
      log_file = case options[:log_file]
      when '-'    then $stdout
      when String then File.open(options[:log_file])
      else
        $stderr
      end
      require 'logger'
      @log = Logger.new(log_file).tap do |l|
        l.level = Logger.const_get((options[:log_level] || 'info').to_s.upcase)
      end
    end

    # Allow overwriting the log attribute.
    attr_writer :log
    
    protected

    # Perform the actual announcement.  Concrete subclasses should
    # override this method.
    # 
    # @param [String] topic
    # @param [Hash] event
    # @param [String] id
    # @return [Hash]
    #
    # @see #announce
    def perform_announce topic, event, id=nil
    end

    # Perform the actual search for events.  Concrete subclasses
    # should override this method.
    # 
    # @param [String] topic
    # @param [Hash] query
    # @return [Array<Hash>]
    #
    # @see #events
    def perform_events topic, query={}
    end

    # Perform the actual search for stashes.  Concrete subclasses
    # should override this method.
    # 
    # @param [String] topic
    # @param [Hash] query
    # @return [Array<Hash>]
    #
    # @see #stashes
    def perform_stashes topic, query={}
    end
    
    # Perform the actual get request.  Concrete subclasses should
    # override this method.
    # 
    # @param [String] topic
    # @param [String] id
    # @return [Object]
    #
    # @see #get
    def perform_get topic, id=nil
    end

    # Perform the actual set! request.  Concrete subclasses should
    # override this method.
    # 
    # @param [String] topic
    # @param [String] id
    # @param [Object] document
    # @return [Object]
    #
    # @see #set!
    def perform_set! topic, id, document
    end

    # Perform the actual set request.  Concrete subclasses should
    # override this method.
    # 
    # @param [String] topic
    # @param [String] id
    # @param [Object] document
    # @return [Object]
    #
    # @see #set
    def perform_set topic, id, document
    end

    # Perform the delete request.  Concrete subclasses should override
    # this method.
    # 
    # @param [String] topic
    # @param [String] id
    # @return [Hash]
    #
    # @see #delete
    def perform_delete topic, id=nil
    end
    
    def extract_topic_event_and_id *args
      if args.first.is_a?(Hash)
        topic = (args.first[:topic] || args.first['topic'])
        event = (args.first[:event] || args.first['event'])
        id    = (args.first[:id]    || args.first['id'])
        raise ArgumentError.new("When using a Hash argument, must provide the :topic key") if topic.nil?
      else
        topic, event, id, _ = args
        raise ArgumentError.new("When using explicit arguments, must provide the topic as the first argument") if topic.nil?
      end
      
      [topic, to_document(event), id]
    end

    def extract_topic_and_id *args
      if args.first.is_a?(Hash)
        topic = (args.first[:topic] || args.first['topic'])
        id    = (args.first[:id]    || args.first['id'])
        raise ArgumentError.new("When using a Hash argument, must provide the :topic key") if topic.nil?
      else
        topic, id, _ = args
        raise ArgumentError.new("When using explicit arguments, must provide the topic as the first argument") if topic.nil?
      end
      [topic, id]
    end

    def extract_topic_id_and_value *args
      if args.first.is_a?(Hash)
        topic = (args.first[:topic] || args.first['topic'])
        id    = (args.first[:id]    || args.first['id'])
        value = (args.first[:value] || args.first['value'])
        raise ArgumentError.new("When using a Hash argument, must provide the :topic key") if topic.nil?
      else
        topic, id, value, _ = args
        raise ArgumentError.new("When using explicit arguments, must provide the topic as the first argument") if topic.nil?
      end
      [topic, id, to_document(value)]
    end

    def extract_topic_and_query *args
      if args.first.is_a?(Hash)
        topic = (args.first[:topic] || args.first['topic'])
        query = (args.first[:query] || args.first['query'])
        raise ArgumentError.new("When using a Hash argument, must provide the :topic key") if topic.nil?
      else
        topic, query, _ = args
        raise ArgumentError.new("When using explicit arguments, must provide the topic as the first argument") if topic.nil?
      end
      [topic, to_document(query)]
    end

  end
end
