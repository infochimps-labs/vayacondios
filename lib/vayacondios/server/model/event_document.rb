# Events also have the following properties, assigned automatically at
# creation if not present:
#
#   * a String `id` used to find and replace events atomically
#   * a String `timestamp` in the default Ruby time format
#
# They also can contain any other arbitrary key-value data.  When
# events are replaced, all their data is replaced atomically.
#
# @example Event representing a build of your app
#
#   EventDocument.new(mongo_database, organization: "my_company", topic: "my_app-builds")
#   
# @example Same event but using the git SHA of the code built as the `id` attribute of the event
#
#   EventDocument.new(mongo_database, organization: "my_company", topic: "my_app-builds", id: "b14e1705c304a2166da847479492ebe59436b2a1")
#
# @example Same event but specified at a different time than "right now"
#
#   EventDocument.new(mongo_database, organization: "my_company", topic: "my_app-builds", timestamp: Time.mktime(2011,12,25))
#
# @example Including the build status and other information in the event.
#
#   EventDocument.new(mongo_database, organization: "my_company", topic: "my_app-builds", status: "Failed", error: "Could not find ...")
#
# Events are currently stored in MongoDB:
#
#   * the collection will be "#{organization}.#{topic}.events"
#   * the `id` will be stored as the `_id` of the corresponding MongoDB document
#   * the `timestamp` will be stored as the `t` of the corresponding MongoDB document
#   * all other values will be stored under the key `d` within the corresponding MongoDB document
#   
class Vayacondios::EventDocument < Vayacondios::MongoDocument

  def initialize(log, mongodb, options = {})
    super(log, mongodb, options)
    self.collection = self.mongo.collection(collection_name)
  end
  
  def find
    raise Golaith::Validation::Error.new(400, "Cannot find an event without an ID") if id.blank?
    result = mongo_query(collection, :find_one, {_id: id})
    if result.present?
      self.id        = result.delete("_id")
      self.timestamp = result['_timestamp'] = result.delete("t")
      result.merge! result.delete("d")
      self.body      = result
      self
    else
      nil
    end
  end

  def create(document)
    document = to_mongo(document)

    @body = document[:d]
    if id
      mongo_query(collection, :update, {:_id => id}, document, {upsert: true})
    else
      response = mongo_query(collection, :insert, document)
      self.id = response
    end

    self
  end
  
  def topic= t
    @topic = t.to_s.gsub(/\W+/, '_')
  end

  protected

  def collection_name
    [organization, topic, 'events'].join('.')
  end

  def to_mongo(document)
    {}.tap do |result|
      result[:d] = document.dup
      result[:_id] = @id if @id
      result[:t] = document.delete(:_timestamp) || Time.now
    end
  end
end
