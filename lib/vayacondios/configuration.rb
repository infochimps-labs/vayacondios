module Vayacondios
  class Configuration

    attr_accessor :base_filename, :load_order

    def initialize(base_fname = nil)
      @base_filename = base_fname || 'vayacondios.yml'
      @load_order    = %w[ global project ]
      @settings      = Configliere::Param.new
    end

    def defaults
      Hash.new
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
      !!@resolved
    end
    
    def resolved_settings
      resolve!
      @resolved_settings.dup
    end
    
    def [] handle
      resolved_settings[handle.to_sym]
    end
 
    def apply_all
      scopes = load_order.dup.unshift(:defaults).push(:overlay)
      scopes.each do |scope|
        conf = send scope
        if conf.is_a? String
          @settings.read_yaml File.read(conf) if File.readable?(conf)
        elsif conf.is_a? Hash
          @settings.deep_merge! conf
        end
      end
    end
    
    def resolve!
      unless resolved?
        apply_all
        @resolved_settings = @settings.to_hash.symbolize_keys
        @resolved = true
      end
    end

  end
end
