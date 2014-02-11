module Vayacondios::Server
  class Configuration < Vayacondios::Configuration

    def defaults
      { 
        development: {
          driver:      'mongo',
          host:        'localhost',
          port:        27017,
          name:        'vayacondios_development',
          connections: 20,
        }
      }      
    end

    def env(handle = nil)
      handle ||= :development
      resolved_settings[handle.to_sym] || {}
    end    
  end
  
  DbConfig = Configuration.new('database.yml') unless defined? DbConfig
end
