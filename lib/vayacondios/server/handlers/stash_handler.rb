module Vayacondios::Server

  # Handles requests against Stashes.
  class StashHandler < DocumentHandler

    # Create a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def create(params={}, document={})
      Stash.create(log, database, params, document)
    end

    # Find and show a particular stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @raise [Goliath::Validation::Error] if no stash is found.  Returns a 404.
    def retrieve params={}, *_
      error_message = ["Stash with topic <#{params[:topic]}>"].tap do |msg|
        msg << "and ID <#{params[:id]}>" if params[:id]
        msg << "not found"
      end.compact.join(' ')
      Stash.find(log, database, params) or raise Goliath::Validation::NotFoundError.new(error_message)
    end

    # Update a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def update(params={}, document={})
      Stash.update(log, database, params, document)
    end

    # Delete a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    def delete params={}, document={}
      Stash.destroy(log, database, params)
    end
  end
end
