module Vayacondios::Server

  # Generic handler for all documents.
  #
  # Handlers link HTTP applications to document classes.
  #
  # @attr [Logger] log the log to use
  # @attr [Driver] database the database driver
  class DocumentHandler
    include Goliath::Chimp::Handler

    attr_reader :log, :database

    # Create a new DocumentHandler.
    #
    # @param [Logger] log
    def initialize(log, db)
      @log = log
      @database = db
    end

    # Search for matching documents.
    #
    # @param [Hash] query the search query
    # @return [Array<Hash>] the matching documents
    def base_search(params, query)
      log.debug("Processing by #{self.class}#search")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Query:      #{query.inspect}")
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
    end

    # Find and show a particular document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @return [Object] the document (or part of a document) that was found
    def base_retrieve(params, document)
      log.debug("Processing by #{self.class}#retrieve")
      log.debug("  Parameters: #{params.inspect}")
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
    end
    
    # Delete a document.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @return [Hash] details about which documents were deleted
    def base_delete(params, document)
      log.debug("Processing by #{self.class}#delete")
      log.debug("  Parameters: #{params.inspect}")
    end

    def call(name, params, document)
      send("base_#{name}", params, document)
      send(name, params, document)
    end

    def action_successful
      { ok: true }
    end
  end
end
