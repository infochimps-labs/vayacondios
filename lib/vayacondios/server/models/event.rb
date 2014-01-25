# Events are documents with arbitrary key/value data but which also
# have
#
# * an ID, auto-generated to a random unique value when none is provided
# * a timestamp, auto-generated to the current time when none is provided
#
# An HTTP request which announces a new event
#
# ```
# POST /v2/coca_cola/event/ad_campaigns
# { "impresions": 23829, "errors": 29 }
# ```
# 
# would result in a document in the `coca_cola.ad_campaigns.events`
# collection with the following structure:
#
# ```
# {
#   "_id": ObjectId("51c38ad981bdb34d32000001"),
#   "t":   ISODate("2013-06-20T23:06:01.846Z"),
#   "d":   {
#     "impressions": 23829,
#     "errors":      29
#   }
# }
# ```
#
# When explictly setting the ID and timestamp with a request like:
#
# ```
# POST /v2/coca_cola/event/ad_campaigns/atx-jan-01
# { "impresions": 23829, "errors": 29, "time": "2013-01-20 18:09:39 -0500" }
# ```
#
# a document would still be generated in the
# `coca_cola.ad_campaigns.events` collection with a similar structure:
#
# ```
# {
#   "_id": "atx-jan-01",
#   "t":   ISODate("2013-01-20T23:09:39Z")
#   "d":   {
#     "impressions": 23829,
#     "errors":      29
#   }
# }
# ```
#
# @attr [Time] timestamp the timestamp for which this event records data
#
module Vayacondios::Server
  class Event < Vayacondios::Server::Document

    # The default number of events returned when searching.
    LIMIT  = 50
    
    # The default sort order when searching
    ORDER  = 'descending'

    # The default sort field when searching.
    SORT   = 'time'

    # The default time window (measured relative to the current time)
    # when searching.
    WINDOW = 3600

    def self.default_query_options
      { limit: LIMIT, order: ORDER, sort: SORT } 
    end

    field :time, Time   # assigned or Time.now.utc
    field :host, String # assigned or read from the client

    # Set the topic of this document, sanitizing it for the database
    #
    # @param [String] name
    # @return [String] the sanitized `name`
    def receive_topic name
      @topic = sanitize_location_name name
    end

    # Normalizes the time
    def receive_time t
      @time = format_time to_timestamp(t)
    end

    # Parses an object into a timestamp.  
    #
    # @param [String, Numeric, Time, nil] obj
    # @param [Time] default the time value to return if none could be found in the `obj`
    # @return [Time]
    def to_timestamp(obj, default = Time.now)
      case obj
      when String  then Time.parse(obj)        
      when Date    then obj.to_time
      when Time    then obj
      when Numeric then Time.at(obj)
      else              default
      end
    rescue ArgumentError => e
      default
    end

    def format_time ts
      ts.round(3).utc
    end

    # The name of the collection this event will store its data in.
    #
    # @return [String]
    def location
      [organization, topic, 'events'].join('.')
    end

    # An events internal database representation
    def document
      { _id: id, _t: time, _d: body }.compact
    end

    # Populate a new Event from a database representation
    def from_document doc
      d = {}.tap do |d|
        d[:id]   = doc[:_id]
        d[:time] = doc[:_t]
        d[:body] = doc[:_d]
      end.compact
      receive! d
      self
    end

    # An event as presented to a user
    def external_document
      { id: id, time: time.iso8601(3) }.merge(body)
    end

    # Returns a Hash that can be used for selection criteria in a query
    # to a MongoDB collection.
    #
    # For any given `query` object, this method should be run **after**
    # Event.projector because Event.projector modifies the `query` by
    # removing certain special options which would otherwise be
    # interpreted by this method..
    #
    # @param [Hash] query
    # @option query [String, Numeric, Time, nil] from the earliest time for a matched event (>=)
    # @option query [String, Numeric, Time, nil] upto the latest time for a matched event (<=)
    # @option query [String, Numeric, Time, nil] after the earliest time for a matched event (>)
    # @option query [String, Numeric, Time, nil] before the latest time for a matched event (<)
    # @option query [String, Regexp]] id a regular expression that matches the ID of the event
    # @return [Hash] the selector Hash
    # @see Event.projector
    def event_filter query
      filter = { _t: {} }.tap do |filter|
        if query.has_key? :after
          filter[:_t][:gt]  = to_timestamp query.delete(:after)
          query.delete(:from)
        elsif query.has_key? :from
          filter[:_t][:gte] = to_timestamp query.delete(:from)
        end

        if query.has_key? :before
          filter[:_t][:lt]  = to_timestamp query.delete(:before)
          query.delete(:upto)
        elsif query.has_key? :upto
          filter[:_t][:lte] = to_timestamp query.delete(:upto)
        end
        # sel['_id'] = Regexp.new(query.delete(:id)) if query[:id]
        query.each_pair{ |key, val| filter[:_d] ||= {} ; filter[:_d][key] = val }
      end
    end

    # Prepare Event search request
    def prepare_search query
      receive!(filter: event_filter(query))
      self
    end

    # Prepare Event retrieve request
    def prepare_find
      raise Error.new('Cannot find an event without an ID') if id.blank?
      self
    end

    # Prepare Event create request
    def prepare_create document
      raise Error.new('Events must be Hash-like to create') unless document.is_a?(Hash)
      document.symbolize_keys!
      receive!(time: document.delete(:time), body: document)
      self
    end

    # Prepare Event remove request
    def prepare_destroy query
      receive!(filter: event_filter(query))
      self
    end  
  end
end
