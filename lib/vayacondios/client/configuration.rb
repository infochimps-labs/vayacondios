module Vayacondios::Client
  class Configuration < Vayacondios::Configuration
    def defaults
      {
        host:    'localhost',
        port:    9000,
        adapter: :net_http,
      }
    end
  end

  ConnectionOpts = Configuration.new unless defined? ConnectionOpts
end
