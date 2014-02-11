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

    def base_uri options
      "http://#{options[:host] || ConnectionOpts[:host]}:#{options[:port] || ConnectionOpts[:port]}/#{Vayacondios::API_VERSION}"
    end
    
    def new_connection(options = {})
      Faraday.new(base_uri options) do |setup|
        setup.adapter  options[:adapter] || ConnectionOpts[:adapter]
        setup.request  :json
        setup.response :json, content_type: /\bjson$/
        if logger = options[:log] || ConnectionOpts[:log]
          setup.response :logger, logger
        end
      end
    end

    def global_connection
      @global_connection ||= new_connection
    end
  end
end
