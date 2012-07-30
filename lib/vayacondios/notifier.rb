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
    
    def notify(topic, cargo = {})
      NoMethodError.unimplemented_method(self)
    end
  end
  
  class LogNotifier < Notifier
    field :client, Whatever, :default => Log
    
    def notify(topic, cargo = {})
      level    = cargo.delete(:level) || :info
      message  = "Notification: #{topic.inspect}."
      message += " Reason: #{cargo.delete(:reason)}." if cargo[:reason]
      message += " Cargo: #{cargo.inspect}"
      client.send(level, message)
    end
  end

  class HttpNotifier < Notifier
    field :client, Vayacondios::HttpClient
    
    def notify(topic, cargo = {})      
      client.insert(cargo, :event, topic)
      nil
    end
  end

  self.notifier = HttpNotifier.receive(client: {})
end
