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
class Vayacondios::Server::Event < Vayacondios::Server::MongoDocument

  # The default number of events returned when searching.
  LIMIT  = 50

  # The default sort order when searching.
  SORT   = ['t', 'descending']

  # The default time window (measured relative to the current time)
  # when searching.
  WINDOW = 3600

  attr_accessor :timestamp

  # Create a new Event.
  #
  # Because of the way Goliath works, the `log` and `database` are
  # created way up inside the `Vayacondios::HttpServer` and have to be
  # passed down into this method at initialization time of an Event.
  #
  # @param [Logger] log the logger instance to use
  # @param [Mongo::Database] database the MongoDB database this event will be stored in
  # @param [Hash] params other parameters for this event
  # @option params [String] organization the name of this event's organization
  # @option params [String] topic the name of this event's topic
  # @option params [String, BSON::ObjectId] :id the ID to use for this event
  # @raise [Error] if no topic was given
  def initialize(log, database, params={})
    super(log, database, params)
    raise Error.new("Must provide a topic when instantiating a #{self.class}") if self.topic.blank?
    self.collection = self.database.collection(collection_name)
  end

  # Set the topic of this document, santizing it for MongoDB.
  #
  # @param [String] name
  # @return [String] the sanitized `name`
  def topic= name
    @topic = sanitize_mongo_collection_name(name)
  end

  # The name of the collection this event will store its data in.
  #
  # @return [String]
  def collection_name
    [organization, topic, 'events'].join('.')
  end

  # Set the timestamp for this event.
  #
  # Will parse its input.
  #
  # @param [String, Numeric, Time, nil] t
  # @return [Time]
  def timestamp= t
    @timestamp = self.class.to_timestamp(t, Time.now.utc)
  end

  # Find an event.
  #
  # If no ID is set, then will perform a search using the given
  # `query`.
  #
  # @param [Hash] query a search query (not used if an ID is present)
  # @return [Hash] the event's formatted body
  # @raise [Error] if this event has no ID
  def find
    raise Error.new("Cannot find an event without an ID") unless id
    result = mongo_query(collection, :find_one, {_id: id})
    if result.present?
      format_event_for_response(result)
    else
      nil
    end
  end

  # Search for events.
  #
  # Some top-level key-value pairs in the `query` Hash have special
  # interpretations, as detailed below.
  #
  # Each other top-level key-value pairs is interpreted as a slice
  # into the MongoDB document (key) and a value that must be matched
  # (value).
  #
  # @param [Logger] log log to write to 
  # @param [Mongo::Database] database MongoDB database
  # @param [Hash] params routing information like `organization`, `topic,`, or `id`
  # @param [Hash] query the search query
  # @option query [Integer] "limit" (50) the number of events to return
  # @option query [Array] "sort" (['t', 'descending']) the sort order for returned events
  # @option query [Array] "fields" an array of fields to return for each event
  # @option query [Time, String, Numeric] "from" the beginning of the time window for returned events
  # @option query [Time, String, Numeric] "upto" the end of the time window for returned events
  # @option query [Time, String, Numeric] "upto" the end of the time window for returned events
  # @option query [Regexp, String] "id" will be matched as a regular expression against the ID of the event
  # @return [Array<Hash>] the matched events
  def self.search log, database, params={}, query={}
    # Make sure to calculate the projector **before** the selector.
    proj    = projector(query)
    reverse = proj.delete(:_reverse)
    sel     = selector(query)
    coll    = new(log, database, params).collection
    results = (mongo_query(log, coll, :find, sel, proj) || []).map do |result|
      new(log, database, params).format_event_for_response(result)
    end
    
    reverse ? results.reverse : results
  end

  # Create a new event.
  #
  # @param [Hash] document the event body
  # @raise [Error] if the event body is not Hash-like
  # @return [Hash] the newly created event with ID and timestamp
  def create(document)
    raise Error.new("Events must be Hash-like to create") unless document.is_a?(Hash)
    mongo_document = format_event_for_mongodb(document)
    self.body      = mongo_document[:d]
    self.timestamp = mongo_document[:t]
    
    if id
      mongo_query(collection, :update, {:_id => id}, mongo_document, {upsert: true})
    else
      response = mongo_query(collection, :insert, mongo_document)
      self.id = response
    end

    document.merge(id: id.to_s, time: timestamp)
  end

  # Parses an object into a timestamp.  
  #
  # @param [String, Numeric, Time, nil] obj
  # @param [Time] default the time value to return if none could be found in the `obj`
  # @return [Time]
  def self.to_timestamp obj, default=nil
    begin
      case obj
      when String
        Time.parse(obj).utc
      when Date
        obj.to_time.utc
      when Time
        obj.utc
      when Numeric
        Time.at(obj).utc
      else
        default
      end
    rescue ArgumentError => e
      default
    end
  end

  # Formats an event as stored in the MongoDB database for the
  # response.
  #
  # @param [Hash] record the event as stored in MongoDB
  # @return [Hash] the event as should be returned in the response
  def format_event_for_response record
    self.timestamp = record['t']
    self.body      = record['d']
    {id: self.class.format_mongo_id(record['_id']).to_s, time: record['t'].utc.iso8601(3)}.merge(record['d'] || {})
  end

  # Reshape an event for storage in MongoDB.
  #
  # @param [Hash] document the original event
  # @return [Hash] the event formatted for MongoDB
  def format_event_for_mongodb(document)
    {}.tap do |result|
      result[:_id] = id if id
      result[:t]   = self.class.to_timestamp(document.delete(:time) || document.delete('time') || self.timestamp, Time.now.utc)
      result[:d]   = document.dup
    end
  end

  # Returns a Hash that can be used to project (limit, sort, pick
  # fields, &c.) a result set from a query to MongoDB.
  #
  # For any given `query` object, this method should be run **before**
  # Event.selector because it modifies the `query` by removing certain
  # special options.
  # 
  # @param [Hash] query
  # @option query [String, Numeric, Time, nil] from the earliest time for a matched event
  # @option query [String, Numeric, Time, nil] upto the latest time for a matched event
  # @option query [String, Regexp]] id a regular expression that matches the ID of the event
  # @return [Hash] the projector Hash
  # @see Event.selector
  def self.projector query={}
    {}.tap do |proj|
      proj[:limit] = (query.delete(:limit) || query.delete('limit') || LIMIT).to_i
      if (query[:sort] || query['sort'])
        proj[:sort]     = (query.delete(:sort) || query.delete('sort'))
        proj[:_reverse] = false
      else
        proj[:sort]     = SORT
        proj[:_reverse] = true
      end
      if fields_spec = (query.delete(:fields) || query.delete('fields'))
        proj[:fields] = [fields_spec].flatten.map { |field_name| "d.#{field_name}" } + ["t", "_id"]
      end
    end
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
  def self.selector(query = {})
    query.symbolize_keys!
    { t: {} }.tap do |sel|
      if query.has_key?(:after)
        sel[:t][:$gt]  = to_timestamp query.delete(:after)
        query.delete(:from)
      else
        sel[:t][:$gte] = to_timestamp(query.delete(:from), (Time.now - WINDOW).utc)
      end
      if query.has_key?(:before)
        sel[:t][:$lt]  = to_timestamp query.delete(:before)
        query.delete(:upto)
      elsif query.has_key?(:upto)
        sel[:t][:$lte] = to_timestamp(query.delete(:upto))
      end
      sel['_id'] = Regexp.new(query.delete(:id)) if query[:id]
      sel.merge!(Hash[query.map { |key, value| ["d.#{key}", value] }])
    end
  end
end
