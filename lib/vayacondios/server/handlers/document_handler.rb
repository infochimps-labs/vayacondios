module Vayacondios::Server

  # Generic handler for all documents.
  #
  # Handlers link HTTP applications to document classes.
  #
  # @attr [Logger] log the log to use
  class DocumentHandler
    include Infochimps::Rack::Handler

    attr_accessor :log, :database

    # Create a new DocumentHandler.
    #
    # @param [Logger] log
    def initialize(log, db)
      self.log = log
      self.database = db
    end

    # Search for matching documents.
    #
    # @param [Hash] query the search query
    # @return [Array<Hash>] the matching documents
    def base_search(params, query)
      log.debug("Processing by #{self.class}#search")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Query:      #{query.inspect}")
      search(params, query)
    end
    
    # Create a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @return [Hash] the created document
    def base_create(params, document)
      log.debug("Processing by #{self.class}#create")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
      create(params, document)
    end

    # Find and show a particular document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @return [Object] the document (or part of a document) that was found
    def base_retrieve(params, document)
      log.debug("Processing by #{self.class}#retrieve")
      log.debug("  Parameters: #{params.inspect}")
      retrieve params
    end
    
    # Update a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @return [Object] the document (or part a document) that was updated
    def base_update(params, document)
      log.debug("Processing by #{self.class}#update")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
      update(params, document)
    end
    
    # Delete a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @return [Hash] details about which documents were deleted
    def base_delete(params, *_)
      log.debug("Processing by #{self.class}#delete")
      log.debug("  Parameters: #{params.inspect}")
      delete(params, *_)
    end

    def call(name, params = {}, document = {})
      send("base_#{name}", params, document)
    end
  end
end
