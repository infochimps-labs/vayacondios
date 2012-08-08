require 'configliere'
require 'gorillib/hash/deep_compact'
require 'gorillib/hash/deep_merge'
require 'gorillib/hash/keys'
require 'vayacondios/http_client'

class Vayacondios
  module Configliere
    def load_from_vayacondios(organization, id, options = {})
      options.symbolize_keys!.deep_merge!(organization: organization)

      client = ::Vayacondios::HttpClient.receive(options.deep_compact!)
      id     = [id, options[:env]].compact.join('.')
      
      begin
        new_data = client.fetch(:config, id)
      rescue ::Vayacondios::HttpClient::Error
        warn "Unable to load vayacondios config '#{id}' for #{organization} at: #{client.host}:#{client.port}"
        new_data = {}
      end
      deep_merge! new_data
      self
    end
    
    def save_to_vayacondios(organization, id, options = {})
      options.symbolize.keys!.deep_merge!(organization: organization)

      client = ::Vayacondios::HttpClient.receive(options.deep_compact!)
      id = [id, options[:env]].compact.join('.')
      
      begin
        client.insert(:config, id)
      rescue ::Vayacondios::HttpClient::Error
        warn "Unable to save vayacondios config '#{id}' for #{organization} at: #{client.host}:#{client.port}"
      end
      self
    end
  end
end

::Configliere::Param.class_eval do
  include ::Vayacondios::Configliere
end
