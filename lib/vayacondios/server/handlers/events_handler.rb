module Vayacondios::Server

  # Handles requests against multiple Events.
  class EventsHandler < DocumentHandler

    # Search for events matching a given query.
    #
    # @param [Hash] params routing information like `organization`, `topic,`, or `id`
    # @param [Hash] query the search query
    def retrieve params={}, query={}
      Event.search(log, database, params, query)
    end

  end
end
