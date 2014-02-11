module Vayacondios
  class HttpClient
    include HttpReadMethods
    include HttpWriteMethods
    include HttpAdminMethods

    attr_reader :organization

    def initialize(options = {})
      @organization = options.delete(:organization)
      setup_connection(options) unless options.empty?
    end

  end
end
