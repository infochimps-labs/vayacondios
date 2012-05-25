require 'configliere'

module Vayacondios

  module Configurable
    STAT_SERVER_PORT = :stat_server_port

    def conf
      @conf ||= Configliere::Param.new STAT_SERVER_PORT => 13622
    end
  end
end
