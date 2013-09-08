# Stashes are documents with arbitrary key/value data.
#
# An HTTP request which sets a new stash
#
# ```
# POST /v2/coca_cola/stash/campaigns
# { "creatives": [ "atx-jan-01", "bos-jan-01"], "test": false }
# ```
#
# would result in a document in the `coca_cola.stash` collection with
# the following structure:
#
# ```
# {
#   "_id": "campaigns",
#   "creatives": [ "atx-jan-01", "bos-jan-01"],
#   "test": false
# }
# ```
#
class Vayacondios::Stash < Vayacondios::MongoDocument

  # The default number of stashes returned when searching.
  LIMIT = 50

  # The default sort order when searching.
  SORT  = ['_id', 'ascending']

  # Returned as an acknowledgement of the request when there is no
  # better option (#destroy, #update_many, &c.)
  OK = {ok: true}

  # Create a new Stash.
  #
  # Because of the way Goliath works, the `log` and `database` are
  # created way up inside the `Vayacondios::HttpServer` and have to be
  # passed down into this method at initialization time of an Stash.
  #
  # @param [Logger] log the logger instance to use
  # @param [Mongo::Database] database the MongoDB database this stash will be stored in
  # @param [Hash] params other parameters for this stash
  # @option params [String] organization the name of this stash's organization
  # @option params [String] topic the name of this stash's topic
  # @option params [String, BSON::ObjectId] :id the ID to use within this stash
  def initialize(log, database, params={})
    super(log, database, params)
    self.collection = self.database.collection(collection_name)
  end

  # The name of the collection this stash will store its data in.
  #
  # @return [String]
  def collection_name
    [organization.to_s, 'stash'].join('.')
  end

  # Sets the ID within this stash to use.
  #
  # @param [String] i an ID
  # @return [String] the ID
  def id= i
    @id = i.to_s if i.present?
  end

  # Sets the topic for this stash.
  #
  # @param [String] t the topic
  # @return [String] the topic
  def topic= t
    if t.nil?
      @topic = nil
    else
      @topic = self.class.format_mongo_id(t) if t.present?
    end
  end

  # Find a stash.
  #
  # If a topic is given but no ID, will return the entire stash for
  # that topic.
  #
  # If a topic and ID are given, will return the ID within the stash
  # of that topic.
  #
  # @param [Hash] query a search query (not used if a topic or ID are present)
  # @return [Object] the stash
  # @raise [Error] if this stash has no topic
  def find
    raise Error.new("Cannot find a stash without a topic") unless topic
    if id.blank?
      result = mongo_query(collection, :find_one, {_id: topic})
      if result.present?
        result.delete("_id")
        self.body = result
      end
    else
      result = mongo_query(collection, :find_one, {_id: topic}, {fields: [id]})
      self.body = extract_id(result)
    end
    self.body
  end

  # Search for stashes.
  #
  # @param [Logger] log log to write to
  # @param [Mongo::Database] database MongoDB database
  # @param [Hash] params routing information like `organization`, `topic,`, or `id`
  # @param [Hash] query the search query
  # @option query [Integer] "limit" (50) the number of stashes to return
  # @option query [Array] "sort" (['_id', 'ascending']) the sort order for returned stashes
  # @option query [String, Regexp] "topic" will be matched as a regular expression against the topic of the stash
  # @return [Array<Hash>] the matched stashes
  def self.search(log, database, params={}, query={})
    # Make sure to calculate the projector **before** the selector.
    proj = projector(query)
    sel  = selector(query)
    coll = new(log, database, params).collection
    (mongo_query(log, coll, :find, sel, proj) || []).map do |result|
      format_stash_from_mongo(result)
    end
  end

  # Create a new stash.
  #
  # Will overwrite any existing stashed value.
  #
  # If an ID and topic are present, will overwrite the ID within the
  # stash of the given topic.
  #
  # If no ID is present, will overwrite the entire stash for the given
  # topic.
  #
  # @param [Hash] document the stash body
  # @return [Object] the stash
  # @raise [Error] if trying to set a non-Hash-like stash at the top-level (without an ID)
  def create document={}
    if id.blank?
      raise Error.new("If not including an _id the document must be a Hash") unless document.is_a?(Hash)
      mongo_query(collection, :update, {:_id => topic}, document.merge(_id: topic), {upsert: true})
    else
      mongo_query(collection, :update, {:_id => topic}, {'$set' => {id => document}}, {upsert: true})
    end
    self.body = document
  end

  # Apply a replacement to all stashes that match a search query
  #
  # @param [Logger] log log to write to
  # @param [Mongo::Database] database MongoDB database
  # @param [Hash] params routing information like `organization`, `topic,`, or `id`
  # @param [Hash] document the body of the request
  # @param [Hash] query the query that stashes must match
  # @option query [String, Regexp] topic interpreted as a regular expression applied to the topic of the stash
  # @option query [Array<String>] topic_in an Array of explicit topics to apply the replacement to
  # @option query [Array<String>] topic_not_in an Array of explicit topics to **not** apply the replacement to
  # @option query [true,false] first (false) apply the replacement only to the first stash which matches the query
  # @param [Hash] replacement update the replacement applied to each matched stash
  def self.replace_many log, database, params={}, query={}, replacement={}
    # Calculate projector and `first` **before** query otherwise their
    # options will be interpreted as fields within the document.
    first = (query.delete(:first) || query.delete('first')) rescue false
    proj  = projector(query)
    sel   = selector(query, true)
    coll  = new(log, database, params).collection
    mongo_query(log, coll, :update, sel, {:$set => replacement}, {
      upsert: false,
      multi:  (first ? false : true)
    })
    OK
  end

  # Update a stash.
  #
  # Will merge the new stash value into the old one.
  #
  # If no ID is present, will merge the new stash for this topic over
  # the existing one.
  #
  # If an ID is present, will merge the new stash's value into the
  # existing stash's value for the ID.  These nested values aren't
  # required to be Hashes, so the merging is done in a datatype-aware
  # way:
  #
  # * if the existing value and new value are Hashes, the new value will be merged on top of the existing value (just as for the top-level without an ID)
  # * if the existing value and the new value are Arrays, the new value will be concatenated to the end of the existing value
  # * if the existing value and the new value are Strings, the new value will be concatenated to the end of the existing value
  # * if the existing value and the new value are Numeric, the new value will be incremented to the existing value
  # * if the existing value and the new value are of different types, then the new value will be overwritten on the existing value
  #
  # @param [Hash] document the body of the stash
  # @return [Object] the stash
  # @raise [Error] if trying to set a non-Hash-like stash at the top-level (without an ID)
  def update(document={})
    find
    if id.blank?
      raise Error.new("If not including an _id the document must be a Hash") unless document.is_a?(Hash)
      self.body = {} unless self.body.is_a?(Hash)
      self.body.deep_merge!(document)
      mongo_query(collection, :update, {_id: topic}, self.body.merge(_id: topic), {upsert: true})
      self.body
    else
      mongo_query(collection, :update, {_id: topic}, {'$set' => to_mongo_update_document(document)} , {upsert: true})
      self.body
    end
  end

  # Apply an update to all stashes that match a search query.
  #
  # @param [Logger] log log to write to
  # @param [Mongo::Database] database MongoDB database
  # @param [Hash] params routing information like `organization`, `topic,`, or `id`
  # @param [Hash] query the query that stashes must match
  # @option query [String, Regexp] topic interpreted as a regular expression applied to the topic of the stash
  # @option query [Array<String>] topic_in an Array of explicit topics to apply the update to
  # @option query [Array<String>] topic_not_in an Array of explicit topics to **not** apply the update to
  # @option query [true,false] first (false) apply the update only to the first stash which matches the query
  # @param [Hash] update the update applied to each matched stash
  def self.update_many log, database, params={}, query={}, update={}
    # Calculate projector and `first` **before** query otherwise their
    # options will be interpreted as fields within the document.
    first = (query.delete(:first) || query.delete('first')) rescue false
    proj  = projector(query)
    sel   = selector(query, true)
    coll  = new(log, database, params).collection

    mutation = {:$inc => {}, :$push => {}, :$set => {}}
    update.each_pair do |key, value|
      case value
      when Numeric
        mutation[:$inc][key]  = value
      when Array
        mutation[:$push][key] = {:$each => value}
      else
        mutation[:$set][key]  = value
      end
    end
    
    mongo_query(log, coll, :update, sel, mutation, {
      upsert: false,
      multi:  (first ? false : true)
    })

    OK
  end
  
  # Destroy a stash.
  #
  # If no ID is present, will delete the entire stash for the given
  # topic.
  #
  # If an ID is present, will delete only the ID field within the
  # stash of the given topic.
  #
  # @return [Hash] an acknowledgement of the topic and ID which were
  #   deleted
  def destroy
    if id.blank?
      mongo_query(collection, :remove, {:_id => topic})
    else
      mongo_query(collection, :update, {:_id => topic}, {'$unset' => { id => 1}})
    end
    OK
  end

  # Apply an update to all stashes that match a search query.
  #
  # @param [Logger] log log to write to
  # @param [Mongo::Database] database MongoDB database
  # @param [Hash] params routing information like `organization`, `topic,`, or `id`
  # @param [Hash] query the query that deleted stashes must match
  # @option query [String, Regexp] topic interpreted as a regular expression applied to the topic of the stash
  # @option query [Array<String>] topic_in an Array of explicit topics to delete
  # @option query [Array<String>] topic_not_in an Array of explicit topics to **not** delete
  def self.destroy_many log, database, params={}, query={}
    # Calculate projector **before** query otherwise their options
    # will be interpreted as fields within the document.
    proj  = projector(query)
    sel   = selector(query, true)
    coll  = new(log, database, params).collection
    mongo_query(log, coll, :remove, sel)
    OK
  end

  protected

  # Construct the document that defines how to update an existing
  # Hash.  Is data-type aware.
  #
  # @param [Object] document the new document
  # @return [Object] the query to pass to MongoDB
  # @raise [Error] if cannot interpret the `document` type
  def to_mongo_update_document document
    case document
    when Hash
      self.body = {} unless self.body.is_a?(Hash)
      self.body.deep_merge!(document)
      Hash[body.map { |key, value| [[id, key].map(&:to_s).join('.'), value] }]
    when Array
      self.body = [] unless self.body.is_a?(Array)
      self.body.concat(document)
      { id => self.body }
    when String
      self.body = '' unless self.body.is_a?(String)
      self.body += document
      { id => self.body }
    when Numeric
      self.body = 0 unless self.body.is_a?(Numeric)
      self.body += document
      { id => self.body }
    else
      raise Error.new("Cannot update using a document of class #{document.class}")
    end
  end

  # Slices a given Mongo `result` with the given `slice` which
  # defaults to this stash's ID.
  #
  # Parses periods in `slice` to allow recursively fetching data from
  # within a document.
  #
  # @param [Hash] result the object to slice into
  # @param [String, nil] slice the slice to take.  Defaults to this Stash's ID.
  # @return [Object] the resulting object
  def extract_id result, slice=nil
    return unless result.present?
    slice = id.dup unless slice
    if slice.include?('.')
      key, new_slice = slice.split('.', 2)
      extract_id(result[key], new_slice)
    else
      result[slice]
    end
  end

  # Returns a Hash that can be used as a projector within a MongoDB
  # query.
  #
  # @param [Hash] query
  # @option query [Integer, String] limit the earliest time for a matched event
  # @option query [Array<String,Array<String>>] sort sort order for stashes
  # @return [Hash] the projector Hash
  # @see Stash.selector
  def self.projector query
    raise Error.new("Must provide a query when trying to match stashes") unless query
    raise Error.new("Query must be a Hash") unless query.is_a?(Hash)
    limit = (query.delete(:limit) || query.delete("limit") || LIMIT).to_i
    sort  = (query.delete(:sort)  || query.delete("sort")  || SORT)
    { sort: sort, limit: limit }
  end

  # Returns a Hash that can be used as a selector within a MongoDB
  # query.
  #
  # @param [Hash] query the query that deleted stashes must match
  # @option query [String, Regexp] topic interpreted as a regular expression applied to the topic of the stash
  # @option query [Array<String>] topic_in an Array of explicit topics to delete
  # @option query [Array<String>] topic_not_in an Array of explicit topics to **not** delete
  # @param [true,false] raise_if_empty whether or not to throw an error if the query is blank
  # @raise [Error] if the query is missing or malformed or if the query is empty and the `raise_if_empty` option is `true`
  # @see Stash.projector
  def self.selector query={}, raise_if_empty=false
    raise Error.new("Must provide a query when trying to match stashes") unless query
    raise Error.new("Query must be a Hash") unless query.is_a?(Hash)
    raise Error.new("Query cannot be empty") if raise_if_empty && query.empty?
    conditions = []
    conditions << { "_id" => Regexp.new(query.delete(:topic) || query.delete('topic'))                  } if (query[:topic]        || query['topic'])
    conditions << { "_id" => { :$in  => (query.delete(:topic_in)     || query.delete('topic_in'))     } } if (query[:topic_in]     || query['topic_in'])
    conditions << { "_id" => { :$nin => (query.delete(:topic_not_in) || query.delete('topic_not_in')) } } if (query[:topic_not_in] || query['topic_not_in'])
    query.each_pair do |key, value|
      conditions << { key => value }
    end
    conditions.empty? ? {} : { :$and => conditions }
  end

  def self.format_stash_from_mongo result
    result['topic'] = result.delete('_id')
    result
  end
  
end
