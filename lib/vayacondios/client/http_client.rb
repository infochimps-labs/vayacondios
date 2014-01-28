module Vayacondios
  class HttpClient
    include HttpMethods

    def initialize(options = {})
      self.organization = options[:organization]
    end

  end
end
