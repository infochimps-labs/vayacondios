require 'vayacondios/client'

module Vayacondios::Client

  # Implements a program `vcd` which makes it easy to interact with
  # Vayacondios from the command-line or from scripts.
  #
  # It makes it easy to use files, pipes, or the command-line itself
  # to pass data to Vayacondios.
  #
  # The 'document' and the 'query' are String inputs passed on the
  # command line.  These String inputs are combined with String inputs
  # read from files named via command-line options or from STDIN to
  # create an array of "inputs" for each command to operate on.
  #
  # @attr [Vayacondios::HttpClient] client the client used to communicate with the server
  # @attr [String] topic the topic of the current request
  # @attr [String] id the ID of the current request
  # @attr [String] document a document read from a file or passed from the command-line
  # @attr [String] query a query read from a file or passed from the command-line
  class CLI

    Error = Class.new(StandardError)

    attr_accessor :client, :topic, :id, :document, :query

    def usage
      <<-USAGE.gsub(/^ {8}/, '').chomp
        usage:
          vcd [ --param=val|--param|-p val|-p ] announce TOPIC [DOCUMENT] [ID]
          vcd [ --param=val|--param|-p val|-p ] get|set|set!|delete TOPIC ID [DOCUMENT]
          vcd [ --param=val|--param|-p val|-p ] events TOPIC QUERY
          vcd [ --param=val|--param|-p val|-p ] stashes QUERY
          vcd [ --param=val|--param|-p val|-p ] set_many|set_many! QUERY_AND_UPDATE
          vcd [ --param=val|--param|-p val|-p ] delete_many QUERY
      USAGE
    end

    def description
      <<-DESCRIPTION.gsub(/^ {8}/, '').chomp
        A command-line Vayacondios client which reads/writes events and
        configuration to/from a Vayacondios server over HTTP.
        
        Announce an event like a successful build of your `foo` project on the
        `foo.build` topic.
        
          $ vcd announce foo.build '{"version": "1.2.3", "status": "success", "time": 27.56}'
        
        You can also announce multiple events at once, perhaps of all your
        projects on the `builds` topic.
        
          $ cat build_events.json
          {"project": "foo", "version": "1.2.3", "status": "success", "time": 27.56}
          {"project": "bar", "version": "0.1.8", "status": "success", "time": 5.22}
          ...
          $ vcd announce builds --file=build_events.json
        
        This works in pipelines too
        
          $ cat build_events.json | vcd announce builds
        
        Events are assigned their own unique ID unless a third ID argument is
        provided.
        
        Events can set their own topics if the contain a `_topic` key and
        their own IDs if they contain an `_id` key.  These fields can
        themselves be customized, see the --topic_field and --id_field
        options.
        
        Stash a configuration value (try the `set!` if you want to
        completely overwrite the old value with the new instead of merging,
        which is the default behavior):
        
          $ vcd set foo admin '{"name": "Bob Jones", "email": "bob@example.com"}'
        
        Retrieve it again
        
          $ vcd get foo admin
          {"name": "Bob Jones", "email": "bob@example.com"}
          
        Or delete it
        
          $ vcd delete foo admin
        
        Getting, setting, or deleting multiple values works the same way as
        for announcing events: either from a file or over STDIN.  Individual
        records can also set their topic and ID just like events.
        
        You can change the Vayacondios host, port, or organization at runtime
        
          $ vcd announce --host=vcd.example.com --organization=myorg foo.build '{"version": "1.2.3", "status": "success", "time": 27.56}'
        
        As well as through YAML configuration files at
        
          /etc/vayacondios/vayacondios.yml
          $PWD/config/vayacondios.yml        
      DESCRIPTION
    end

    # Returns the cmdline used for the `vcd` program.
    #
    # @return [Configliere::Param]
    def cmdline
      return @cmdline if @cmdline
      c = Configliere::Param.new.use :commandline
      usg = self.usage
      c.define_singleton_method(:usage){ usg }
      c.description = self.description
      
      c.define :host,         flag: 'h',                                    description: "Host for Vayacondios server"
      c.define :port,         flag: 'p', type: Integer,                     description: "Port for Vayacondios server"
      c.define :organization, flag: 'o',                 default: 'vcd',    description: "Organization to write data for"
      c.define :topic_field,                             default: '_topic', description: "Field used to dynamically determine the topic of a record"
      c.define :id_field,                                default: '_id',    description: "Field used to dynamically determine the ID of a record"
      c.define :file,         flag: 'f',                                    description: "Read input from file" 
      c.define :log_file,                                                   description: "Path to log file (defaut: STDOUT)"
      c.define :log_level,                               default: 'INFO',   description: "Log level"
      c.define :pretty,       flag: 'p', type: :boolean, default: false,    description: "Pretty-print output"
      c.define :dry_run,                 type: :boolean, default: false,    description: "Don't perform any actual requests"
      @cmdline = c
    end

    # Run a new instance of the `vcd` program.
    #
    # Instantiates a new instance of CLI and takes it through its
    # lifecycle.
    #
    # @raise [SystemExit] when execution stops either because requests are complete or a fatal error has occured
    def self.run
      cli = new
      begin
        cli.boot
        cli.run
      rescue Error => e
        $stderr.puts e.message
        exit(1)
      end
    end

    def boot
      cmdline.resolve!
      self.client = HttpClient.new(cmdline)
      log.debug "Created client with settings: #{cmdline}"
    end

    # Run the desired command.
    #
    # @raise [Error] if the desired command is unknown
    def run
      command = cmdline.rest.shift
      cmdline.dump_help if command.nil?
      if available_commands.include? command
        send command
      else
        raise Error.new "Unknown command: <#{command}>.  Must be one of #{available_commands.inspect}"
      end
    end

    #
    # == Commands ==
    #

    def available_commands
      %w[ announce events clear_events get get_many set set! unset unset_many ]
    end
    
    # Announce one or many events.
    #
    # Will read the topic as the first argument, the document as the
    # second, and the ID as the third.
    #
    # Will iterate over each input and announce it as an event.  It
    # will attempt to find a topic and ID within each event and will
    # fall back to using its own as a default.
    #
    # @raise [Error] if no topic was given
    def announce
      self.topic    = cmdline.rest.shift or raise Error.new('Must provide a topic when announcing an event')
      self.document = cmdline.rest.shift
      self.id       = cmdline.rest.shift
      raise Error.new("Must provide an event to announce via the second command-line argument, the --file argument, or STDIN.") unless input?
      inputs do |event|
        handle_response client.announce(topic_for(event), event, id_for(event))
      end
    end

    # Search for events.
    #
    # Will read the topic as the first argument and the query as the
    # second.
    #
    # For each input, will send it as a query.  Will attempt to find a
    # topic in the query itself and will fall back to using its own as
    # a default.
    #
    # Results are printed out one per-line.
    #
    # @raise [Error] if no topic was given
    def events
      self.topic    = cmdline.rest.shift or raise Error.new("Must provide a topic when searching for events")
      self.query    = cmdline.rest.shift || '{}'
      inputs do |query|
        handle_response client.events(topic_for(query), query)
      end
    end

    def clear_events
      self.topic    = cmdline.rest.shift or raise Error.new("Must provide a topic when deleting events")
      self.query    = cmdline.rest.shift || '{}'
      inputs do |query|
        handle_response client.clear_events(topic_for(query), query)
      end
    end
    # Get a single stashed value.
    #
    # Will read the topic as the first argument as the ID as the
    # second.
    #
    # For each input, will use it to get a stash.  Will attempt to
    # find a topic and ID in the input and will fall back to using its
    # own as a default.
    #
    # @raise [Error] when no topic was given
    def get
      self.topic = cmdline.rest.shift or raise Error.new('Must provide a topic when getting a stash')
      self.id    = cmdline.rest.shift
      if input?
        inputs do |req|
          handle_response client.get(topic_for(req), id_for(req))
        end
      else
        handle_response client.get(topic, id)
      end
    end

    # Search for multiple stashed values.
    #
    # Will read the query as the first argument.
    #
    # For each input will use it as a query.
    def get_many
      self.query = (cmdline.rest.shift || '{}')
      inputs do |query|
        handle_response client.get_many(query)
      end
    end

    # Set a value by merging it into a (potentially) existing value.
    #
    # Will read the topic as the first argument, ID as the second, and
    # document as the third.
    #
    # For each input, will merge that input.  Will attempt to read a
    # topic and ID for each input and will fall back to its own as a
    # default.
    #
    # @raise [Error] if no topic was given
    def set
      self.topic    = cmdline.rest.shift or raise Error.new('Must provide a topic when setting a stash')
      self.document = cmdline.rest.shift
      self.id       = cmdline.rest.shift
      raise Error.new("Must provide a document to stash via the third command-line argument, the --file argument, or STDIN.") unless input?
      inputs do |doc|
        handle_response client.set(topic_for(doc), id_for(doc), doc)
      end
    end

    # Set a value by overwriting a (potentially) existing value.
    #
    # Will read the topic as the first argument, ID as the second, and
    # document as the third.
    #
    # For each input, will write that input.  Will attempt to read a
    # topic and ID for each input and will fall back to its own as a
    # default.
    #
    # @raise [Error] if no topic was given
    def set!
      self.topic    = cmdline.rest.shift or raise Error.new('Must provide a topic when setting a stash')
      self.document = cmdline.rest.shift
      self.id       = cmdline.rest.shift
      raise Error.new("Must provide a document to stash via the third command-line argument, the --file argument, or STDIN.") unless input?
      inputs do |doc|
        handle_response client.set!(topic_for(doc), id_for(doc), doc)
      end
    end
    
    # Delete a stashed value.
    #
    # Will read the topic as the first argument and ID as the second.
    #
    # For each input, will delete that input.  Will attempt to read a
    # topic and ID for each input and will fall back to its own as a
    # default.
    #
    # @raise [Error] if no topic was given
    def unset
      self.topic = cmdline.rest.shift or raise Error.new('Must provide a topic when deleting a stash')
      self.id    = cmdline.rest.shift
      if input?
        inputs do |req|
          handle_response client.unset(topic_for(req), id_for(req))
        end
      else
        handle_response client.unset(topic, id)
      end
    end

    # Delete many stashes that match some criteria.
    #
    # Each input should be a query Hash.
    #
    # @raise [Error] if no input was given
    def unset_many
      self.document = cmdline.rest.shift
      raise Error.new("Must provide a query via the second command-line argument, the --file argument, or STDIN.") unless input?
      inputs do |query|
        handle_response client.unset_many(query)
      end
    end
    
    #
    # == Inputs == 
    #

    # Were there any inputs?
    #
    # Input is either a document passed on the command-line, a file
    # requested to be read from the command-line, or is imminent
    # because data is queuing up on STDIN.
    #
    # @return [true, false]
    def input?
      document || cmdline.file || input_on_stdin?
    end

    # For each input, parse each line as a JSON record and yield it to
    # the given block.
    #
    # First the document and/or query will be processed, then any file
    # named on the command-line, then data over STDIN.
    #
    # @yield [input] yields each parsed line from each input
    # @yieldparam [Hash,Array,String,Numeric,nil] input the input
    def inputs(&block)
      raw_inputs do |line|
        begin
          yield MultiJson.load(line)
        rescue => e
          log.error("#{e.class} -- #{e.message}")
          $stderr.puts(e.backtrace)
        end
      end
    end

    protected
    
    def raw_inputs(&block)
      case
      when document || query
        [document, query].compact.each(&block)
      when cmdline.file
        File.open(cmdline.file).each(&block)
      when input_on_stdin?
        $stdin.each(&block)
      end
    end

    # Is there data pending to be read on STDIN?
    #
    # @return [true, false]
    def input_on_stdin?
      ! $stdin.tty?
    end
    
    #
    # == Routing ==
    #

    # Return the topic for the given document.
    #
    # Will read key named by #topic_field if present, otherwise the
    # default topic.
    #
    # @param [Hash] doc
    # @return [String] topic
    def topic_for doc
      return topic unless doc.is_a?(Hash)
      doc.delete(cmdline.topic_field) || topic
    end

    # Return the ID for the given document.
    #
    # Will read key named by #id_field if present, otherwise the
    # default ID.
    #
    # @param [Hash] doc
    # @return [String] id
    def id_for doc
      raw_id = doc.is_a?(Hash) ? (doc.delete(cmdline.id_field) || id) : id
      raw_id == '-' ? nil : raw_id
    end

    #
    # == Output == 
    #

    # Handle the JSON response that returns from the Vayacondios
    # server by printing it out, one response per-line.
    #
    # If the `pretty` option was specified then the data will be
    # pretty-printed first.
    #
    # @param [Hash, Array, String, Numeric, nil] doc any of the core JSON types
    def handle_response res
      if res.success?
        puts MultiJson.dump(res.body, pretty: cmdline.pretty)
      else
        puts res.body['error']
      end
    end

    #
    # == Log ==
    #

    # Where to send log output.
    #
    # @return [IO]
    def log_output
      case cmdline.log_file
      when '-'    then $stdout
      when String then File.open(log_file)
      else
        $stderr
      end
    end

    public

    # The log that will be used by the `vcd` program as it runs.
    #
    # @return [Logger]
    def log
      return @log if @log
      require 'logger'
      @log = Logger.new(log_output)
      @log.level = Logger.const_get(cmdline.log_level.upcase)
      @log
    end
    
  end
end
