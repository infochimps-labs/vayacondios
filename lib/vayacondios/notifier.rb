require 'gorillib/exception/raisers'
require 'gorillib/metaprogramming/class_attribute'
require 'vayacondios/client'

class Vayacondios
  class_attribute :notifier

  def self.notify(*args)
    self.notifier.notify(*args)
  end

  class Notifier < Vayacondios
    def notify(topic, cargo={})
      NoMethodError.unimplemented_method(self)
    end
  end

  class HttpNotifier < Notifier
    def initialize(options={})
      options = Settings.vayacondios.merge(options) if defined?(Settings)
  
      @host         = options[:host]
      @port         = options[:port]
      @organization = options[:organization]
  
      @client       =  ::Vayacondios::Client.new(@host, @port, @organization)
    end
  
    def notify(topic, cargo={})
      raise "Cannot notify with unset host" if @host.nil?
      raise "Cannot notify with unset port" if @port.nil?
      raise "Cannot notify with unset organization" if @organization.nil?
      
      @client.insert(cargo, :event, topic)
      nil
    end
  end

  self.notifier = HttpNotifier.new
end