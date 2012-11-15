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
      type = attrs.delete(:type)
      case type
      when 'http'        then HttpNotifier.new(attrs)
      when 'log'         then LogNotifier.new(attrs)
      when 'none','null' then NullNotifier.new(attrs)
      else
        raise ArgumentError, "<#{type}> is not a valid build option"
      end
    end
  end

  def self.default_notifier() NotifierFactory.receive(type: 'log') ; end

  module Notifications
    extend Gorillib::Concern
    include Gorillib::Configurable

    def notify(topic, cargo = {})
      notifier.notify(topic, cargo)
    end

    included do
      class_eval do
        config(:notifier, Vayacondios::NotifierFactory, default: Vayacondios.default_notifier)
      end
    end

  end

  extend Notifications
  self.notifier = default_notifier
end
