module Vayacondios::Server
  class Configuration < Vayacondios::Configuration

    def defaults
      %w[development test production].inject({}) do |default_conf, type|
        default_conf[type.to_sym] = {
          driver:      'mongo',
          host:        'localhost',
          port:        27017,
          name:        "vayacondios_#{type}",
          connections: 20,
        }
        default_conf
      end
    end

    def env(handle = nil)
      handle ||= :development
      resolved_settings[handle.to_sym] || {}
    end
  end

  DbConfig = Configuration.new('database.yml') unless defined? DbConfig
end
