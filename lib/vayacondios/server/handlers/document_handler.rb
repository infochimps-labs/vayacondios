class Vayacondios

  class DocumentHandler

    attr_accessor :log, :mongo

    def initialize(log, mongo)
      self.log   = log
      self.mongo = mongo
    end

    def find options={}
      log.debug("Processing by #{self.class}#find")
      log.debug("  Parameters: #{options.inspect}")
    end

    def create(options={}, document={})
      log.debug("Processing by #{self.class}#create")
      log.debug("  Parameters: #{options.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end
    
    def update(options={}, document={})
      log.debug("Processing by #{self.class}#update")
      log.debug("  Parameters: #{options.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end

    def patch options={}, document={}
      log.debug("Processing by #{self.class}#patch")
      log.debug("  Parameters: #{options.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end

    def delete options={}
      log.debug("Processing by #{self.class}#delete")
      log.debug("  Parameters: #{options.inspect}")
    end
    
  end
end
