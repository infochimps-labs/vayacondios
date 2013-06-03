require 'configliere'
class Vayacondios

  class CLI

    Error = Class.new(StandardError)

    attr_accessor :client, :topic, :id, :document

    def settings
      @settings ||= Configliere::Param.new.tap do |s|
        s.use :commandline

        def s.usage
          <<USAGE
usage:
  vcd [ --param=val|--param|-p val|-p ] announce TOPIC [DOCUMENT] [ID]
  vcd [ --param=val|--param|-p val|-p ] get|set|set!|delete TOPIC ID [DOCUMENT]
USAGE
        end
        
        s.description = <<DESCRIPTION
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
  ~/.vayacondios.yml

DESCRIPTION
        
        s.define :host,         description: "Host for Vayacondios server",    default: "localhost",         env_var: "VCD_HOST",         flag: 'h'
        s.define :port,         description: "Port for Vayacondios server",    default: 9000, type: Integer, env_var: "VCD_PORT",         flag: 'p'
        s.define :organization, description: "Organization to write data for", default: "vayacondios",       env_var: "VCD_ORGANIZATION", flag: 'o'

        s.define :topic_field, description: "Field used to dynamically determine the topic of a record", default: "_topic"
        s.define :id_field,    description: "Field used to dynamically determine the ID of a record",    default: "_id"

        s.define :file,  description: "Read input from file", flag: 'f'

        s.define :log_file,  description: "Path to log file (defaut: STDOUT)"
        s.define :log_level, description: "Log level", default: "INFO"

        s.define :pretty, description: "Pretty-print output", type: :boolean, default: false, flag: 'p'
      end
    end

    def boot
      settings.read("/etc/vayacondios/vayacondios.yml")    if File.exist?("/etc/vayacondios/vayacondios.yml")
      settings.read(File.expand_path("~/.vayacondios.yml")) if ENV["HOME"] && File.exist?(File.expand_path("~/.vayacondios.yml"))
      settings.resolve!
      self.client = HttpClient.new(log: log, host: settings.host, port: settings.port, organization: settings.organization)
      log.debug("Connected to #{client.host}:#{client.port}")
    end
    
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

    def run
      command = settings.rest.shift
      case command
      when 'announce' then announce
      when 'get'      then get
      when 'set'      then set
      when 'set!'     then set!
      when 'delete'   then delete
      when nil        then settings.dump_help
      else
        raise Error.new("Unknown command: <#{command}>.  Must be either 'announce' or one of 'get', 'set', 'set!', or 'delete'.")
      end
    end

    #
    # == Commands ==
    #

    def announce
      self.topic    = (settings.rest.shift or raise Error.new("Must provide a topic when announcing an event"))
      self.document = settings.rest.shift
      self.id       = settings.rest.shift
      raise Error.new("Must provide an event to announce via the second command-line argument, the --file argument, or STDIN.") unless input?
      inputs do |event|
        handle_response(client.announce(topic_for(event), event, id_for(event)))
      end
    end

    def get
      self.topic = (settings.rest.shift or raise Error.new("Must provide a topic when getting a stash"))
      self.id    = settings.rest.shift
      if input?
        inputs do |req|
          handle_response(client.get(topic_for(req), id_for(req)))
        end
      else
        handle_response(client.get(topic, id))
      end
    end

    def set
      self.topic    = (settings.rest.shift or raise Error.new("Must provide a topic when setting a stash"))
      self.id       = settings.rest.shift
      self.document = settings.rest.shift
      raise Error.new("Must provide a document to stash via the third command-line argument, the --file argument, or STDIN.") unless input?
      inputs do |doc|
        handle_response(client.set(topic_for(doc), id_for(doc), doc))
      end
    end

    def set!
      self.topic    = (settings.rest.shift or raise Error.new("Must provide a topic when setting a stash"))
      self.id       = settings.rest.shift
      self.document = settings.rest.shift
      raise Error.new("Must provide a document to stash via the third command-line argument, the --file argument, or STDIN.") unless input?
      inputs do |doc|
        handle_response(client.set!(topic_for(doc), id_for(doc), doc))
      end
    end

    def delete
      self.topic = (settings.rest.shift or raise Error.new("Must provide a topic when deleting a stash"))
      self.id    = settings.rest.shift
      if input?
        inputs do |req|
          handle_response(client.delete(topic_for(req), id_for(req)))
        end
      else
        handle_response(client.delete(topic, id))
      end
    end

    #
    # == Inputs == 
    #

    def input?
      document || settings.file || input_on_stdin?
    end

    def inputs(&block)
      raw_inputs do |line|
        begin
          yield MultiJson.load(line)
        rescue => e
          log.error("#{e.class} -- #{e.message}")
        end
      end
    end

    protected
    
    def raw_inputs(&block)
      case
      when document
        [document].each(&block)
      when settings.file
        File.open(settings.file).each(&block)
      when input_on_stdin?
        $stdin.each(&block)
      end
    end

    def input_on_stdin?
      ! $stdin.tty?
    end
    
    #
    # == Routing ==
    #
    
    def topic_for doc
      return topic unless doc.is_a?(Hash)
      doc.delete(settings.topic_field) || topic
    end

    def id_for doc
      raw_id = doc.is_a?(Hash) ? (doc.delete(settings.id_field) || id) : id
      raw_id == '-' ? nil : raw_id
    end

    #
    # == Output == 
    #
    
    def handle_response doc
      case
      when doc && settings.pretty
        puts MultiJson.dump(doc, pretty: true)
      when doc
        puts MultiJson.dump(doc)
      else
      end
    end

    #
    # == Log ==
    #

    def log_output
      case settings.log_file
      when '-'    then $stdout
      when String then File.open(log_file)
      else
        $stderr
      end
    end

    public

    def log
      return @log if @log
      require 'logger'
      @log = Logger.new(log_output)
      @log.level = Logger.const_get(settings.log_level.upcase)
      @log
    end
    
  end
end
