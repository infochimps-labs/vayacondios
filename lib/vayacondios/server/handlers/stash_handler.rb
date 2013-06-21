class Vayacondios

  # Handles requests against Stashes.
  class StashHandler < MongoDocumentHandler
    
    # Find a stashs.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query a search query
    # @raise [Goliath::Validation::Error] if no stash is found.  Returns a 404.
    def find params={}, query={}
      super(params, query)
      if result = Stash.find(log, database, params, query)
        return result
      end
      raise Goliath::Validation::Error.new(404, ["Stash with topic <#{params[:topic]}>"].tap do |msg|
        msg << "and ID <#{params[:id]}>" if params[:id]
        msg << "not found"
      end.compact.join(' '))
    end

    # Create a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def create(params={}, document={})
      super(params, document)
      Stash.create(log, database, params, document)
    end

    # Update a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def update(params={}, document={})
      super(params, document)
      Stash.update(log, database, params, document)
    end

    # Patch a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def patch params={}, document={}
      super(params, document)
      Stash.patch(log, database, params, document)
    end

    # Delete a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    def delete params={}
      super(params)
      Stash.destroy(log, database, params)
    end

  end
end
