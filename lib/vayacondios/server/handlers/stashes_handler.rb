module Vayacondios::Server
  class StashesHandler < DocumentHandler

    # Apply a replacement across many stashes.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the request containing a search query and a replacement
    # def create(params, document)
    #   document.symbolize_keys!
    #   query       = document[:query]  || {}
    #   replacement = document[:update] || {}
    #   Stash.replace_many(params, query, replacement)
    # end

    # Search for stashes matching a given query.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query a search query
    def retrieve(params, query)
      stashes = Stash.search(params, query) do |request, filter, options|
        database.call(:search, request, filter, options)
      end
    end
    
    # Apply an update across many stashes.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] document the body of the request containing a search query and an update
    # def update(params={}, document={})
    #   query  = (document[:query]  || document['query']  || {})
    #   update = (document[:update] || document['update'] || {})
    #   Stash.update_many(log, database, params, query, update)
    # end

    # Delete many stashes that match a query.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query a search query
    # @param [Hash] document the body of the request containing a search query and an update
    def delete(params, query)
      raise Goliath::Validation::BadRequestError.new 'Query cannot be empty' if query.empty?
      Stash.destroy(params, query) do |request, filter|
        database.call(:remove, request, filter)
      end
      action_successful
    end

  end
end
