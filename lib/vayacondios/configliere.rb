require 'configliere'

class Vayacondios
  DEFAULT_VAYACONDIOS_CONFIG = { :host => 'localhost', :port => 8000 }

  module Configliere
    def vayacondios organization, id, options={}
      require 'vayacondios/client'
      
      options  = options.inject({}){|hsh, pair| hsh.merge({pair[0].to_sym => pair[1]}) }
      options  = DEFAULT_VAYACONDIOS_CONFIG.merge(options)
      client   = ::Vayacondios::Client.new(options[:host], options[:port], organization)

      id = [id, options[:env]].join('.') if options[:env]
      
      begin
        new_data = client.config.fetch(id)
      rescue ::Vayacondios::Client::Error
        warn "Unable to load vayacondios config '#{id}' for #{organization} at: #{options[:host]}:#{options[:port]}"
        new_data = {}
      end
      deep_merge! new_data
      self
    end
  end
end

::Configliere::Param.class_eval do
  include ::Vayacondios::Configliere
end