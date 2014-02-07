module Vayacondios
  class HttpClient
    include HttpReadMethods
    include HttpWriteMethods
    include HttpAdminMethods

    attr_reader :organization

    def initialize(options = {})
      @organization = options[:organization]
    end

  end
end
