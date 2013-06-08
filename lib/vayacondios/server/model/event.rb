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

  LIMIT  = 1000
  SORT   = ['t', 'descending']
  WINDOW = 3600

  attr_accessor :timestamp

  def initialize(log, database, params={})
    super(log, database, params)
    raise Error.new("Must provide a topic when instantiating a #{self.class}") if self.topic.blank?
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
      Time.parse(obj).utc
    when Date
      obj.to_time.utc
    when Time
      obj.utc
    else
      Time.now.utc
    end
  end
  
  def find query={}
    if id.blank?
      return search(query)
    else
      result = mongo_query(collection, :find_one, {_id: id})
      if result.present?
        self.timestamp = result["t"]
        self.body      = result["d"]
        self.body
      else
        nil
      end
    end
  end

  def search query
    opts = {}
    opts[:limit]  = (query.delete("limit")  || LIMIT).to_i
    opts[:sort]   = (query.delete("sort")   || SORT)
    opts[:fields] = query.delete("fields") if query["fields"]
    
    where = {}
    if query['time'].is_a?(Hash)
      spec = query.delete('time')
      from = parse_timestamp(spec['from'])
      upto = parse_timestamp(spec['upto'])
      if from || upto
        where['t'] = {}
        where['t'][:gte] = from if from
        where['t'][:lte] = upto if upto
      end
    end
    where.merge!(Hash[query.map { |key, value| ["d.#{key}", value] }])
    where["t"] ||= { gte: Time.now - WINDOW }
    mongo_query(collection, :find, where, opts)
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

  def parse_timestamp t
    return if t.blank?
    begin
      case t
      when String  then Time.parse(t)
      when Numeric then Time.at(t)
      end
    rescue => e
      nil
    end
  end
end
