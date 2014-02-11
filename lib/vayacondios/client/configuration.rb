module Vayacondios::Client
  class Configuration < Vayacondios::Configuration
    def defaults
      {
        host:    Vayacondios::DEFAULT_SERVER_ADDRESS,
        port:    Vayacondios::DEFAULT_SERVER_PORT,
        adapter: :net_http,
      }
    end
  end

  ConnectionOpts = Configuration.new unless defined? ConnectionOpts
end
