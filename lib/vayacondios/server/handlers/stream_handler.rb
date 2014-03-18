module Vayacondios::Server
  class StreamHandler < EventsHandler

    attr_reader :cursor, :timer, :on_data

    def retrieve(params, query)
      @timer = EM::Synchrony.add_periodic_timer(1){ stream_events }
      @options = Event.extract_query_options! query.merge(order: 'asc')
      @cursor = Event.receive(params).prepare_search(query)
      Goliath::Response::STREAMING
    end

    def stream_data(&on_data)
      @on_data = on_data
      self
    end

    def close_stream!
      timer.cancel
    end

    def projection_options
      @options.dup
    end

    def update_cursor latest
      cursor.filter.delete(:_t)
      cursor.prepare_search(after: latest)
    end

    def stream_events
      log.debug 'Streaming events'
      log.debug "  Stream cursor is #{cursor.filter}"
      available = database.call(:search, cursor, cursor.filter.dup, projection_options)
      unless available.empty?
        available.each do |result|
          event = Event.new.format_response(result)
          on_data.call event
          update_cursor event[:time]
        end
      end
    end
  end
end
