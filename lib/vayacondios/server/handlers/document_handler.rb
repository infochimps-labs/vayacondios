class Vayacondios

  # Generic handler for all documents.
  #
  # Handlers link HTTP applications to document classes.
  #
  # @attr [Logger] log the log to use
  class DocumentHandler

    attr_accessor :log

    # Create a new DocumentHandler.
    #
    # @param [Logger] log
    def initialize(log)
      self.log = log
    end

    # Find a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query a search query
    def find params={}, query={}
      log.debug("Processing by #{self.class}#find")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{query.inspect}")
    end

    # Create a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    def create(params={}, document={})
      log.debug("Processing by #{self.class}#create")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end
    
    # Update a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    def update(params={}, document={})
      log.debug("Processing by #{self.class}#update")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end

    # Patch a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    def patch params={}, document={}
      log.debug("Processing by #{self.class}#patch")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end

    # Delete a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    def delete params={}
      log.debug("Processing by #{self.class}#delete")
      log.debug("  Parameters: #{params.inspect}")
    end
    
  end
end
