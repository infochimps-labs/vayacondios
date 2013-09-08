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

    # Find and show a particular document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @return [Object] the document (or part of a document) that was found
    def show params={}, *_
      log.debug("Processing by #{self.class}#show")
      log.debug("  Parameters: #{params.inspect}")
    end

    # Search for matching documents.
    #
    # @param [Hash] query the search query
    # @return [Array<Hash>] the matching documents
    def search params={}, query={}
      log.debug("Processing by #{self.class}#search")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Query:      #{query.inspect}")
    end
    
    # Create a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @return [Hash] the created document
    def create(params={}, document={})
      log.debug("Processing by #{self.class}#create")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end
    
    # Update a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @return [Object] the document (or part a document) that was updated
    def update(params={}, document={})
      log.debug("Processing by #{self.class}#update")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
    end
    
    # Delete a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @return [Hash] details about which documents were deleted
    def delete params={}, *_
      log.debug("Processing by #{self.class}#delete")
      log.debug("  Parameters: #{params.inspect}")
    end
    
  end
end
