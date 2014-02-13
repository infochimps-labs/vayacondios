module Vayacondios::Client
  class HttpClient
    include HttpRead, HttpWrite, HttpAdmin

    attr_reader :organization

    def initialize(options = {})
      @organization = options.delete(:organization)
      configure_connection(options) unless options.empty?
    end

  end
end
