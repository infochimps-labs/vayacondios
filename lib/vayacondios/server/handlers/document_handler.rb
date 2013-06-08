class Vayacondios

  class DocumentHandler

    attr_accessor :log

    def initialize(log)
      self.log = log
    end
    
    def find params={}, document={}
      log.debug("Processing by #{self.class}#find")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end

    def create(params={}, document={})
      log.debug("Processing by #{self.class}#create")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end
    
    def update(params={}, document={})
      log.debug("Processing by #{self.class}#update")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end

    def patch params={}, document={}
      log.debug("Processing by #{self.class}#patch")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end

    def delete params={}, document={}
      log.debug("Processing by #{self.class}#delete")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end
    
  end
end
