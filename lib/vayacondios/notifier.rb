require 'gorillib/builder'
require 'gorillib/exception/raisers'
require 'gorillib/logger/log'
require 'gorillib/metaprogramming/class_attribute'
require 'vayacondios/http_client'

class Vayacondios
  class_attribute :notifier

  module Notifications 

    def notify(topic, cargo = {})
      notifier.notify(topic, cargo)
    end
    
    def self.included(base)
      base.class_attribute :notifier
      base.notifier = Vayacondios.notifier
    end

  end
  
  extend Notifications
  
  class Notifier < Vayacondios
    include Gorillib::Builder

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
  
  class LogNotifier < Notifier
    field :client, Whatever, :default => Log
    
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
    field :client, Vayacondios::HttpClient
    
    def notify(topic, cargo = {})
      prepped = prepare(cargo)
      client.insert(prepped, :event, topic)
      nil
    end
  end

  self.notifier = HttpNotifier.receive(client: {})
end
