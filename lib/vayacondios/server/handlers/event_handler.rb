module Vayacondios::Server

  # Handles requests against Events.
  class EventHandler < DocumentHandler

    # Find and show a particular event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @raise [Goliath::Validation::Error] if no event is found.  Returns a 404.
    def retrieve params={}, *_
      Event.find(log, database, params) or raise Goliath::Validation::NotFoundError.new("Event with topic <#{params[:topic]}> and ID <#{params[:id]}> not found")
    end
    
    # Create an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    def create(params={}, document={})
      Event.create(log, database, params, document)
    end    
  end
end
