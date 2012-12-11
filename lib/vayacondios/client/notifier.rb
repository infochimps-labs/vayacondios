class Vayacondios

  class_attribute :notifier

  class Notifier < Vayacondios
    attr_accessor :client

    def prepare(obj)
      case
      when obj.respond_to?(:to_inspectable) then obj.to_inspectable
      when obj.respond_to?(:to_wire)        then obj.to_wire
      when obj.respond_to?(:to_hash)        then obj.to_hash
      else
        raise ArgumentError.new("Cannot notify '#{obj.inspect}' -- require a hash-like object.")
      end
    end

    def notify(topic, cargo = {})
      NoMethodError.unimplemented_method(self)
    end
  end

  class NullNotifier < Notifier
    def initialize(*args) ; end
    
    def notify topic, cargo={}
    end
  end

  class LogNotifier < Notifier

    def initialize(options = {})
      @client = options[:log] || Log
    end

    def notify(topic, cargo = {})
      prepped  = prepare(cargo)
      level    = prepped.delete(:level) || :info
      message  = "Notification: #{topic.inspect}."
      message += " Reason: #{prepped.delete(:reason)}." if prepped[:reason]
      message += " Cargo: #{prepped.inspect}"
      client.send(level, message)
    end
  end

  class HttpNotifier < Notifier

    def initialize(options = {})
      @client = Vayacondios::HttpClient.receive(options)
    end

    def notify(topic, cargo = {})
      prepped = prepare(cargo)
      client.insert(prepped, :event, topic)
      nil
    end
  end

  class NotifierFactory
    def self.receive(attrs = {})
      type = attrs[:type]
      case type
      when 'http'        then HttpNotifier.new(attrs)
      when 'log'         then LogNotifier.new(attrs)
      when 'none','null' then NullNotifier.new(attrs)
      else
        raise ArgumentError, "<#{type}> is not a valid build option"
      end
    end
  end

  def self.default_notifier(log = nil) NotifierFactory.receive(type: 'log', log: log) ; end

  module Notifications

    def notify(topic, cargo = {})
      notifier.notify(topic, cargo)
    end

    def self.included klass
      if klass.ancestors.include? Gorillib::Model
        klass.class_eval do
          field :notifier, Vayacondios::NotifierFactory, default: Vayacondios.default_notifier
          
          def receive_notifier params
            params.merge!(log: try(:log)) if params[:type] == 'log'
            @notifier = Vayacondios::NotifierFactory.receive(params)
          end
        end
      else
        klass.class_attribute :notifier
        klass.notifier = Vayacondios.default_notifier try(:log)
      end
    end

  end

  extend Notifications
  self.notifier = default_notifier
end
