def ENV.root_path(*args)
  File.expand_path(File.join(File.dirname(__FILE__), '../../../', *args))
end

require 'configliere'

Settings.read(ENV.root_path('config/vayacondios.yaml'))
