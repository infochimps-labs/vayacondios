module Vayacondios::Server
  class EventHandler < DocumentHandler

    # Create an event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    def create(params, document)
      Event.create(params, document) do |request|
        database.call(:insert, request)
      end
    end

    # Find and show a particular event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @raise [Goliath::Validation::Error] if no event is found.  Returns a 404.
    def retrieve(params, document)
      Event.find(params) do |request|
        database.call(:retrieve, request)
      end or raise Goliath::Validation::NotFoundError.new("Event with topic <#{params[:topic]}> and ID <#{params[:id]}> not found")
    end

    # Delete a specific event.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the document
    # @raise [Goliath::Validation::Error] if params do not have an id
    def delete(params, document)
      raise Goliath::Validation::BadRequestError.new('An <Id> is required to delete an Event') unless params[:id]
      Event.destroy(params, {}) do |request, options|
        database.call(:remove, request, options)
      end
      action_successful
    end
  end
end
