class Vayacondios

  class CLI

    Error = Class.new(StandardError)

    attr_accessor :client, :topic, :id

    def settings
      @settings ||= Configliere::Param.new.tap do |s|
        s.use :commandline

        def s.usage
          'usage: vcd [ --param=val|--param|-p val|-p ] event|config topic id'
        end
        
        s.description = "A command-line client to read and write events and configuration to and from a Vayacondios server."
        
        s.define :host,         description: "Host for Vayacondios server",    default: "localhost",         env_var: "VCD_HOST", flag: 'h'
        s.define :port,         description: "Port for Vayacondios server",    default: 9000, type: Integer, env_var: "VCD_PORT", flag: 'p'
        s.define :organization, description: "Organization to write data for", default: "vayacondios",       env_var: "VCD_ORGANIZATION", flag: 'o'

        s.define :update,  description: "Update instead of create", type: :boolean, default: false, flag: 'u'
        s.define :delete,  description: "Delete instead of create", type: :boolean, default: false, flag: 'd'

        s.define :file,  description: "Read input from file", flag: 'f'
        s.define :value, description: "Use given value", flag: 'v'

        s.define :log_file,  description: "Path to log file (defaut: STDOUT)"
        s.define :log_level, description: "Log level", default: "INFO"

        s.define :pretty, description: "Pretty-print output", type: :boolean, default: false, flag: 'p'
      end
    end

    def boot
      settings.read("/etc/vayacondios/vayacondios.yml")    if File.exist?("/etc/vayacondios/vayacondios.yml")
      settings.read(File.expand_path("~/vayacondios.yml")) if ENV["HOME"] && File.exist?(File.expand_path("~/vayacondios.yml"))
      settings.resolve!
      self.client = HttpClient.new(log, settings.host, settings.port, settings.organization)
      log.debug("Connected to #{client.uri}")
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
      when 'event'
        run_event_command
      when 'config'
        run_config_command
      when nil
        settings.dump_help
      else
        raise Error.new("Unknown command: <#{command}>.  Must be one of 'event' or 'config'")
      end
    end

    protected

    def run_config_command
      self.topic = (settings.rest.shift or raise Error.new("Must provide a topic as the second argument when getting/setting configs"))
      self.id    = (settings.rest.shift or raise Error.new("Must provide an ID as the third argument when getting/setting configs"))
      case
      when settings[:delete]
        handle_response(client.delete_config(topic, id))
      when has_input?
        if settings[:update]
          handle_response(client.set_config(topic, id, input))
        else
          handle_response(client.config!(topic, id, input))
        end
      else
        handle_response(client.config(topic, id))
      end
    end

    def run_event_command
      if has_input?
        self.topic = (settings.rest.shift or raise Error.new("Must provide a topic as the second argument when getting/posting events"))
        self.id    = settings.rest.shift
        inputs do |input|
          params = [event_topic_for_input(input), input, event_id_for_input(input)]
          handle_response(client.event!(*params))
        end
      else
        self.topic = (settings.rest.shift or raise Error.new("Must provide a topic as the second argument when getting events"))
        self.id    = (settings.rest.shift or raise Error.new("Must provide an ID as the third argument when getting events"))
        handle_response(client.event(topic, id))
      end
    end

    def handle_response response
      log.debug("#{response.code} -- #{response.class}")
      case response
      when Net::HTTPOK
        if settings.pretty && response.body && (!response.body.empty?)
          pretty = (MultiJson.dump(MultiJson.load(response.body), pretty: true) rescue response.body)
          puts pretty
        else
          puts response.body
        end
      when Net::HTTPNotFound
      else
        log.error(response.body)
      end
    end

    def event_topic_for_input input
      return topic unless input.is_a?(Hash)
      input.delete("_topic") || topic
    end

    def event_id_for_input input
      return id unless input.is_a?(Hash)
      input.delete("_id") || id
    end
    
    def has_input?
      settings.value || settings.file || input_on_stdin?
    end

    def input_on_stdin?
      ! $stdin.tty?
    end

    def raw_inputs(&block)
      case
      when settings.value
        [settings.value].each(&block)
      when settings.file
        File.open(settings.file).each(&block)
      when input_on_stdin?
        $stdin.each(&block)
      end
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
    
    def input
      case
      when settings.value
        MultiJson.load(settings.value)
      when settings.file
        MultiJson.load(File.read(settings.file))
      when input_on_stdin?
        MultiJson.load($stdin.read)
      end
    end

    def log_output
      case settings.log_file
      when '-'    then $stdout
      when String then File.open(log_file)
      else
        $stderr
      end
    end

    def log
      return @log if @log
      require 'logger'
      @log = Logger.new(log_output).tap do |l|
        l.level = Logger.const_get(settings.log_level.to_s.upcase)
      end
    end
    
  end
end
