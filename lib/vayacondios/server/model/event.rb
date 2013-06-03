# Events also have the following properties, assigned automatically at
# creation if not present:
#
#   * a String `id` used to find and replace events atomically
#   * a String `timestamp` in the default Ruby time format
#
# They also can contain any other arbitrary key-value data.  When
# events are replaced, all their data is replaced atomically.
#
# Events are currently stored in MongoDB:
#
#   * the collection will be "#{organization}.#{topic}.events"
#   * the `id` will be stored as the `_id` of the corresponding MongoDB document
#   * the `timestamp` will be stored as the `t` of the corresponding MongoDB document
#   * all other values will be stored under the key `d` within the corresponding MongoDB document
#   
class Vayacondios::Event < Vayacondios::MongoDocument

  attr_accessor :timestamp

  def initialize(log, database, params={})
    super(log, database, params)
    self.collection = self.database.collection(collection_name)
  end

  def collection_name
    [organization, topic, 'events'].join('.')
  end

  def timestamp= t
    @timestamp = to_timestamp(t)
  end
  
  def to_timestamp obj
    case obj
    when String
      Time.parse(obj)
    when Date
      obj.to_time
    when Time
      obj
    else
      Time.now
    end
  end
  
  def find
    raise Goliath::Validation::Error.new(400, "Must provide the ID of the event to find") if id.blank?
    result = mongo_query(collection, :find_one, {_id: id})
    if result.present?
      self.timestamp = result["t"]
      self.body      = result["d"]
      self.body
    else
      nil
    end
  end

  def create(document)
    raise Goliath::Validation::Error.new(400, "Events must be Hash-like to create") unless document.is_a?(Hash)
    mongo_document = to_mongo_create_document(document)
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

  def to_mongo_create_document(document)
    {}.tap do |result|
      result[:_id] = id if id
      result[:t]   = to_timestamp(document[:time] || document['time'] || self.timestamp)
      result[:d]   = document.dup
    end
  end
end
