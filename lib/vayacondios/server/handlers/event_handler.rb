class Vayacondios

  # Handles requests against Events.
  class EventHandler < MongoDocumentHandler

    # Find and show a particular event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @raise [Goliath::Validation::Error] if no event is found.  Returns a 404.
    def show params={}, *_
      super(params)
      Event.find(log, database, params) or raise Goliath::Validation::Error.new(404, "Event with topic <#{params[:topic]}> and ID <#{params[:id]}> not found")
    end

    # Search for events matching a given query.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query the search query
    def search params={}, query={}
      super(params, query)
      Event.search(log, database, params, query)
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

    # Delete an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @raise [Goliath::Validation::Error] since events cannot be deleted.  Returns a 400.
    def delete params={}, document={}
      super(params)
      raise Goliath::Validation::Error.new(400, "Cannot delete events")
    end
    
  end
end
