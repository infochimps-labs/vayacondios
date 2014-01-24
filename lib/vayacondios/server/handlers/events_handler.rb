module Vayacondios::Server

  # Handles requests against multiple Events.
  class EventsHandler < DocumentHandler

    # Search for events matching a given query.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query the search query
    def search(params, query)
      Event.search(params, query) do |request, filter, opts|
        database.call(:search, request, filter, opts)
      end
    end

    # FIXME
    # Abstract this into method delegation
    def base_retrieve(params, query)
      base_search(params, query)
    end
    alias_method :retrieve, :search

    def delete(params, query)
      Event.destroy(params, query) do |request, opts|
        database.call(:remove, request, opts)
      end
      action_successful
    end

  end
end
