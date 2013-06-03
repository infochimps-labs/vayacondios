class Vayacondios

  # Represents an abstract implementation of a Vayacondios client.
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
  # For each API method (`announce`, `get`, `set`, &c.) a concrete
  # subclass should implement the corresponding `perform_` method
  # (`perform_announce`, `perform_get`, `perform_set`, &c.)
  class Client

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
    # 
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
    # @example Announce an SSH intrusion event in your network on topic `intrusions`
    #
    #   client.announce('intrusions', ip: '10.123.123.123', priority: 3, type: 'ssh')
    #   #=> {"id"=>"51aae2f181bdb31d10000007", "time"=>"2013-06-02 01:15:13 -0500", "ip"=>"10.123.123.123", "priority"=>"3", "type"=>"ssh"}
    #
    # If you don't specify an ID for the event, one will be generated
    # by the server and returned to you, as above.  You can pass an ID
    # is as the third argument.
    #
    # @example Announce a new build of your project on topic `builds` with ID given by the SHA1 of your commit.
    #
    #   client.announce('builds', { name: 'Little Stinker', version: '1.2.3', status: 'success', duration: 183 }, '13fe3ff5f13c6b0394cc22501a9617cfe2445c63')
    #   #=> {"id"=>"13fe3ff5f13c6b0394cc22501a9617cfe2445c63", "time"=>"2013-06-02 01:15:13 -0500", "name"=>"Little Stinker", "version"=>"1.2.3", "status"=>"success", "duration"=>183}
    #
    # Similarly, if you don't specify the time of the event, the
    # current time (upon arrival at the server) will be used.  You can
    # set the time of the event explicitly by including the `time` key
    # in your event data.
    #
    # @example Setting an explicit time for an event
    #
    #   client.announce('intrusions', ip: '10.123.123.123', priority: 3, type: 'ssh', time: "2013-06-02 00:00:00 -0000")
    #   #=> {"id"=>"51aae2f181bdb31d10000007", "time"=>"2013-06-02 00:00:00 -0000", "ip"=>"10.123.123.123", "priority"=>"3", "type"=>"ssh"}
    #
    # Setting the time and the ID are done in different places because
    # the ID is related to the *label* (equivalently the *routing*) of
    # the event while the time is related to the *data* of the event.
    #
    # If this client is in dry run mode the request will be logged
    # instead of sent.
    #
    # @param [String] topic the topic to announce on
    # @param [Hash] event the event to announce
    # @param [String, nil] id the optional ID for the event
    # @return [Hash] the event returned by the server in acknowledgement
    def announce topic, event, id=nil
      doc = to_document(event)
      if dry_run?
        msg  = "Announcing <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{doc.inspect}"
        log.debug(msg)
        nil
      else
        perform_announce(topic, doc, id)
      end
    end

    # Retrieve a stash.
    #
    # Requires a topic.  If an ID is given, will return the stash for
    # the ID within the topic, otherwise the stash for the entire
    # topic.
    #
    # @example Retrieve a list of firewall rules on the topic `firewall` under the ID `webservers`
    #
    #   client.get('firewall', 'webservers')
    #
    # @example Retrieve a list of all firewall rules on the topic `firewall`
    #
    #   client.get('firewall')
    #
    # Will return whatever value is stored at the corresponding topic
    # and ID or `nil` if none is found.
    #
    # If the client is in dry run mode, the request will be logged
    # instead of sent.
    #
    # @param [String] topic
    # @param [String, nil] id
    # @return [Object] the value stored fore the given `topic` and `id`
    def get topic, id=nil
      if dry_run?
        msg  = "Getting <#{topic}>"
        msg += "/<#{id}>" if id
        log.debug(msg)
        nil
      else
        perform_get(topic, id)
      end
    end

    # Set a stash by replacing it with the given document.
    #
    # A topic is required when setting a stash.
    #
    # @example Replace existing firewall rules with new ones for the topic `firewall` and ID `webservers`
    #
    #   client.set!('firewall', 'webservers', internet: {port: 80, range: '*'}, blacklisted: ['10.123.123.123'])
    #
    # In this example, if other data existing within the stash for
    # topic `firewall` and ID `webservers` it would be replaced with
    # the contents above.
    #
    # @param [String] topic
    # @param [String] id
    # @param [Object] document
    def set! topic, id, document
      doc = to_document(document)
      if dry_run?
        msg  = "Replacing <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{doc.inspect}"
        log.debug(msg)
      else
        perform_set!(topic, id, doc)
      end
    end

    # Set a stash by merging the given document into it.
    #
    # A topic is required when setting a stash.
    #
    # @example Set a new firewall rule on the topic `firewall` for the ID `webservers`
    #
    #   client.set('firewall', 'webservers', internet: {port: 80, range: '*'})
    #
    # In this example, other data existing within the stash for topic
    # `firewall` and ID `webservers` would be merged alongside the new
    # `internet` fields.
    #
    # @param [String] topic
    # @param [String] id
    # @param [Object] document
    def set topic, id, document
      doc = to_document(document)
      if dry_run?
        msg  = "Merging <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{doc.inspect}"
        log.debug(msg)
      else
        perform_set(topic, id, doc)
      end
    end

    # Delete a stash.
    #
    # @param [String] topic
    # @param [String] id
    def delete topic, id=nil
      if dry_run?
        msg  = "Deleting <#{topic}>"
        msg += "/<#{id}>" if id
        log.debug(msg)
      else
        perform_delete(topic, id)
      end
    end

    # Convert an object into a simple document that can be serialized
    # and sent to the server.
    #
    # Objects which define "standard" methods (`to_hash`, `to_a`) will
    # have those methods called to turn them into simple documents.
    #
    # In usual usage, this method is essentially just returning the
    # Hash you probably called it with.
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
      when obj.respond_to?(:to_a)           then obj.to_a           # longstanding convention

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

    # Perform the actual announcement.  Concrete subclasses should
    # override this method.
    # 
    # @param [String] topic
    # @param [String] id
    # @return [Object]
    #
    # @see #get
    def perform_get topic, id=nil
    end

    # Perform the actual announcement.  Concrete subclasses should
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

    # Perform the actual announcement.  Concrete subclasses should
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

    # Perform the actual announcement.  Concrete subclasses should
    # override this method.
    # 
    # @param [String] topic
    # @param [String] id
    # @return [Hash]
    #
    # @see #delete
    def perform_delete topic, id=nil
    end

  end
end
