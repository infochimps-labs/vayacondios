class Vayacondios

  # Handles requests against Events.
  class EventHandler < MongoDocumentHandler

    # Find an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query a search query
    # @raise [Goliath::Validation::Error] if no event is found.  Returns a 404.
    def find params={}, query={}
      super(params, query)
      if result = Event.find(log, database, params, query)
        return result
      else
        raise Goliath::Validation::Error.new(404, "Event with topic <#{params[:topic]}> and ID <#{params[:id]}> not found")
      end
    end
    
    # Create an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    def create(params={}, document={})
      super(params, document)
      Event.create(log, database, params, document)
    end

    # Update an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @raise [Goliath::Validation::Error] since events cannot be updated.  Returns a 400.
    def update(params={}, document={})
      super(params, document)
      raise Goliath::Validation::Error.new(400, "Cannot update events")
    end
    
    # Patch an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @raise [Goliath::Validation::Error] since events cannot be patched.  Returns a 400.
    def patch params={}, document={}
      super(params, document)
      raise Goliath::Validation::Error.new(400, "Cannot patch events")
    end

    # Delete an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @raise [Goliath::Validation::Error] since events cannot be deleted.  Returns a 400.
    def delete params={}
      super(params)
      raise Goliath::Validation::Error.new(400, "Cannot delete events")
    end
    
  end
end
