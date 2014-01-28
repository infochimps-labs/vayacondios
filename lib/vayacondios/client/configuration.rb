module Vayacondios
  class Configuration
    attr_accessor :base_filename, :load_order

    def initialize
      @base_filename = 'vayacondios.yml'
      @load_order    = %w[ defaults global project ]
      @settings      = Configliere::Param.new
    end

    def defaults
      {
        host:    'localhost',
        port:    9000,
        adapter: :net_http,
        log:     Logger.new($stderr)
      }
    end

    def global
      File.join('/etc/vayacondios', base_filename)
    end
    
    def project
      File.join(ENV['PWD'], 'config', base_filename)
    end
    
    def overlay(conf = nil)
      @overlay = conf unless conf.nil?
      @overlay
    end
    
    def resolved?
      @resolved
    end
    
    def resolved_settings
      resolve! unless resolved?
      @resolved_settings
    end
    
    def [] handle
      resolved_settings[handle.to_sym]
    end
    
    def to_s
      resolved_settings
    end
 
    def apply_all
      load_order.dup.push(:overlay).each do |scope|
        conf = send scope
        if conf.is_a? String
          @settings.read_yaml File.read(conf) if File.readable?(conf)
        elsif conf.is_a? Hash
          @settings.deep_merge! conf
        end
      end
    end
    
    def resolve!
      apply_all
      @resolved_settings = @settings.to_hash.symbolize_keys
      @resolved = true
    end
  end

  ConnectionOpts = Configuration.new unless defined? ConnectionOpts
end
