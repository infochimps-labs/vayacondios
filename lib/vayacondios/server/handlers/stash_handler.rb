module Vayacondios::Server
  class StashHandler < DocumentHandler

    # Create a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    def create(params, document)      
      stash = Stash.create(params, document) do |request|
        database.call(:insert, request)
      end
      stash.delete(:topic)
      stash
    end

    # Find and show a particular stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @raise [Goliath::Validation::Error] if no stash is found.  Returns a 404.
    def retrieve(params, document)
      stash = Stash.find(params) do |request|
        database.call(:retrieve, request)
      end or raise Goliath::Validation::NotFoundError.new("Stash with topic <#{params[:topic]}> not found")
      stash.delete(:topic)
      if slice = params[:id]
        stash[slice.to_sym] or raise Goliath::Validation::NotFoundError.new("Stash with topic <#{params[:topic]}> found, but does not contain Id <#{slice}>")
      else
        stash
      end
    end

    # Update a stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the stash
    # def update(params, document)
    #   id = params.delete(:id)
    #   raise Goliath::Validation::BadRequestError.new("If not including an id the document must be a Hash") if id.blank? && !document.is_a?(Hash)
    #   # Not sure if I like this behavior for updating a non-existant document
    #   original = begin ; retrieve(params.dup, nil) ; rescue Goliath::Validation::NotFoundError ; nil ; end
    #   if original.is_a? Hash
    #     if id
    #       original.delete(id.to_sym)
    #       original.merge!(id => document) unless document.nil?
    #     else
    #       original.merge! document
    #     end
    #   else
    #     params[:id] = id if id && document
    #     original = document
    #   end
    #   Stash.update(params, original) do |request|
    #     database.call(:update, request)
    #   end
    # end
 
    # Delete a single stash.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document presentation or filter information
    def delete(params, document)
      raise Goliath::Validation::NotImplementedError.new 'Deleting an Id from a Stash is not supported' if params[:id]
      Stash.destroy(params, {}) do |request, options|
        database.call(:remove, request, options)
      end
      action_successful
    end
  end
end
