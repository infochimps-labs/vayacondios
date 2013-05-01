class Vayacondios

  class Client

    Error = Class.new(StandardError)

    attr_accessor :options

    attr_writer :log
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

    def initialize options={}
      self.options = options
      self.log     = options[:log] if options[:log]
    end

    def dry_run?
      options[:dry_run]
    end

    def announce topic, event, id=nil
      doc = to_document(event)
      if dry_run?
        msg  = "Announcing <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{doc.inspect}"
        log.debug(msg)
      else
        perform_announce(topic, doc, id)
      end
    end
    
    def get topic, id
      if dry_run?
        msg  = "Getting <#{topic}>"
        msg += "/<#{id}>" if id
        log.debug(msg)
      else
        perform_get(topic, id)
      end
    end

    def set! topic, id, config
      doc = to_document(config)
      if dry_run?
        msg  = "Replacing <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{doc.inspect}"
        log.debug(msg)
      else
        perform_set!(topic, id, doc)
      end
    end

    def set topic, id, config
      doc = to_document(config)
      if dry_run?
        msg  = "Updating <#{topic}>"
        msg += "/<#{id}>" if id
        msg += ": #{doc.inspect}"
        log.debug(msg)
      else
        perform_set(topic, id, doc)
      end
    end

    def delete topic, id
      if dry_run?
        msg  = "Deleting <#{topic}>"
        msg += "/<#{id}>" if id
        log.debug(msg)
      else
        perform_delete(topic, id)
      end
    end
    
    protected

    def perform_announce topic, event, id=nil
    end

    def perform_get topic, id
    end

    def perform_set! topic, id, config
    end
    
    def perform_set topic, id, config
    end

    def perform_delete topic, id
    end

    def to_document obj
      case
      when obj.respond_to?(:to_vayacondios) then obj.to_vayacondios # special behavior for VCD
      when obj.respond_to?(:to_wire)        then obj.to_wire        # support gorillib
      when obj.respond_to?(:to_hash)        then obj.to_hash        # support many things
      when obj.respond_to?(:to_h)           then obj.to_h           # new 2.0 convention
      else
        {}
      end
    end
    
  end
end
