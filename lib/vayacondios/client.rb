require 'faraday'
require 'faraday_middleware'
require 'gorillib'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/string/inflections'
require 'logger'
require 'multi_json'

require 'vayacondios'
require 'configliere'
require 'vayacondios/configuration'
require 'vayacondios/client/configuration'
require 'vayacondios/client/http_methods'
require 'vayacondios/client/http_client'

module Vayacondios
  module Client

    module_function

    def base_uri
      "http://#{Vayacondios::ConnectionOpts[:host]}:#{Vayacondios::ConnectionOpts[:port]}/v2"
    end
    
    def new_connection
      Faraday.new(base_uri) do |setup|
        setup.request  :json
        setup.response :json, content_type: /\bjson$/
        setup.response :logger, Vayacondios::ConnectionOpts[:log] if Vayacondios::ConnectionOpts[:log]
        setup.adapter  Vayacondios::ConnectionOpts[:adapter]
      end
    end

    def global_connection
      @global_connection ||= new_connection
    end
  end
end
