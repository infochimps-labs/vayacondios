class Vayacondios

  # Handles requests against Stashes.
  class StashHandler < MongoDocumentHandler

    # Find and show a particular stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @raise [Goliath::Validation::Error] if no stash is found.  Returns a 404.
    def show params={}, *_
      super(params)
      error_message = ["Stash with topic <#{params[:topic]}>"].tap do |msg|
        msg << "and ID <#{params[:id]}>" if params[:id]
        msg << "not found"
      end.compact.join(' ')
      Stash.find(log, database, params) or raise Goliath::Validation::Error.new(404, error_message)
    end

    # Search for stashes matching a given query.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query a search query
    def search params={}, query={}
      super(params, query)
      Stash.search(log, database, params, query)
    end
    
    # Create a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def create(params={}, document={})
      super(params, document)
      Stash.create(log, database, params, document)
    end

    # Apply a replacement across many stashes.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the request containing a search query and a replacement
    def replace_many(params={}, document={})
      log.debug("Processing by #{self.class}#replace_many")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
      query       = (document[:query]  || document['query']  || {})
      replacement = (document[:update] || document['update'] || {})
      Stash.replace_many(log, database, params, query, replacement)
    end
    
    # Update a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def update(params={}, document={})
      super(params, document)
      Stash.update(log, database, params, document)
    end

    # Apply an update across many stashes.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the request containing a search query and an update
    def update_many(params={}, document={})
      log.debug("Processing by #{self.class}#update_many")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Document:   #{document.inspect}")
      query  = (document[:query]  || document['query']  || {})
      update = (document[:update] || document['update'] || {})
      Stash.update_many(log, database, params, query, update)
    end

    # Delete a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    def delete params={}, document={}
      super(params)
      Stash.destroy(log, database, params)
    end

    # Delete many stashes that match a query.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query a search query
    # @param [Hash] document the body of the request containing a search query and an update
    def delete_many(params={}, query={})
      log.debug("Processing by #{self.class}#delete_many")
      log.debug("  Parameters: #{params.inspect}")
      log.debug("  Query:      #{query.inspect}")
      Stash.destroy_many(log, database, params, query)
    end
    
  end
end
