class Vayacondios

  class Notifier < Vayacondios

    attr_reader :options
    
    def initialize options={}
      @options = options
    end

    def prepare(obj)
      case
      when obj.respond_to?(:to_inspectable) then obj.to_inspectable
      when obj.respond_to?(:to_wire)        then obj.to_wire
      when obj.respond_to?(:to_hash)        then obj.to_hash
      else
        raise ArgumentError.new("Cannot notify '#{obj.inspect}' -- require a hash-like object.")
      end
    end

    def notify(topic, cargo={})
      raise NoMethodError.new("Define the #{self.class}#notify method")
    end

    def get topic, id
      raise NoMethodError.new("Define the #{self.class}#get method")
    end
    
    def set topic, id, cargo={}
      raise NoMethodError.new("Define the #{self.class}#set method")
    end

    def merge topic, id, cargo={}
      raise NoMethodError.new("Define the #{self.class}#merge method")
    end
  end

  class LocalNotifier < Notifier

    def initialize opts={}
      super(opts)
      @configs   = Hash.new({})
      @log       = options[:log] if options[:log]
    end

    def log_output
      case options[:log_file]
      when '-'    then $stdout
      when String then File.open(options[:log_file])
      else
        $stderr
      end
    end

    def log
      return @log if @log
      require 'logger'
      @log = Logger.new(log_output).tap do |l|
        l.level = Logger.const_get((options[:log_level] || 'info').to_s.upcase)
      end
    end
    
    def notify topic, cargo={}
      prepped  = prepare(cargo)
      level    = prepped.delete(:_level) || :info
      message  = "#{topic.inspect}: #{prepped.inspect}"
      log.send(level, message)
    end

    def get topic, id
      @configs[topic.to_s][id.to_s]
    end

    def set topic, id, cargo={}
      prepped = prepare(cargo)
      @configs[topic.to_s][id.to_s] = prepped
      log.debug("/#{topic}/#{id} = #{prepped.inspect}")
    end

    def merge topic, id, cargo={}
      prepped = prepare(cargo)
      @configs[topic.to_s][id.to_s].deep_merge!(prepped)
      log.debug("/#{topic}/#{id} <- #{prepped.inspect}")
    end

    def delete topic, id
      @configs[topic.to_s].delete(id.to_s)
      log.debug("/#{topic}/#{id} X")
    end
    
  end

  class NullNotifier < LocalNotifier
    def notify topic, cargo={}
    end
  end

  class HttpNotifier < LocalNotifier

    def client
      @client ||= Vayacondios::HttpClient.new(log, options[:host], options[:port], options[:organization])
    end

    def notify(topic, cargo = {})
      prepped = prepare(cargo)
      client.event!(topic, prepped)
    end

    def get topic, id
      client.config(topic, id)
    end

    def set topic, id, cargo={}
      prepped = prepare(cargo)
      client.config!(topic, id, prepped)
    end

    def merge topic, id, cargo={}
      prepped = prepare(cargo)
      client.set_config!(topic, id, prepped)
    end

    def delete topic, id
      client.delete_config!(topic, id)
    end
  end

  class NotifierFactory
    def self.receive(attrs = {})
      type = attrs[:type]
      case type
      when 'http'        then HttpNotifier.new(attrs)
      when 'local'       then LocalNotifier.new(attrs)
      when 'none','null' then NullNotifier.new(attrs)
      else
        raise ArgumentError, "<#{type}> is not a valid build option"
      end
    end
  end

  module Notifications

    def notify(topic, cargo = {})
      notifier.notify(topic, cargo)
    end

    def set(topic, id, cargo = {})
      notifier.set(topic, id, cargo)
    end
    
    def merge(topic, id, cargo = {})
      notifier.merge(topic, id, cargo)
    end
    
    def delete(topic, id)
      notifier.delete(topic, id)
    end

    def self.included klass
      if klass.respond_to?(:field) && klass.respond_to?(:receive)
        klass.class_eval do
          field :notifier, Vayacondios::NotifierFactory, default: Vayacondios.default_notifier, :doc => "Notifier used to get or set out-of-band data"
          def receive_notifier params
            params.merge!(log: try(:log)) if params[:type] == 'local'
            @notifier = Vayacondios::NotifierFactory.receive(params)
          end
        end
      else
        klass.instance_eval do
          def notifier= n
            @notifier = n
          end
          def notifier
            @notifier
          end
        end
        klass.notifier = Vayacondios.default_notifier try(:log)
      end
    end
  end
  
  def self.default_notifier(log = nil)
    LocalNotifier.new(:log => log)
  end
  
  extend Notifications
end
