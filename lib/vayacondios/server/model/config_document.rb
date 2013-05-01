# ConfigDocuments are key-value paris.  In additional to the
# `organization` and `topic` properties of the Document class they can
# be created with arbitrary key-value data.
#
# Configuration documents are currently stored in MongoDB:
#
#   * the collection will be "#{organization}.config"
#   * the `topic` of the config will be used as the `_topic` of the corresponding MongoDB document
#   * all other key-value data will be stored within the corresponding MongoDB document
#
class Vayacondios::ConfigDocument < Vayacondios::MongoDocument

  attr_reader :field
  
  def initialize(log, mongodb, options = {})
    super(log, mongodb, options)

    self.collection = self.mongo.collection(collection_name)
    self.field  = options[:field] ||= options[:id]
  end

  def field= f
    @field = f.to_s.gsub(/\W/, '') if f.present?
  end

  def find
    raise Goliath::Validation::Error.new(400, "Cannot find a config without a topic") if topic.blank?
    if id.blank?
      result = mongo_query(collection, :find_one, {_id: topic})
      if result.present?
        result.delete("_id")
        self.body = result
      end
    else
      result = mongo_query(collection, :find_one, {_id: topic}, {fields: [id]})
      if result.present? && result.has_key?(id)
        result.delete("_id")
        self.body = result[id]
      end
    end
    self if self.body
  end

  def create document={}
    raise Goliath::Validation::Error.new(400, "Must provide a topic to create") if topic.blank?
    if id.blank?
      result = mongo_query(collection, :find_one, {_id: topic})
      mongo_query(collection, :update, {:_id => topic}, document.merge(_id: topic), {upsert: true})
      self.body = document
    else
      mongo_query(collection, :update, {:_id => topic}, {'$set' => {id => document, _id => topic}}, {upsert: true})
      self.body = {} unless self.body
      self.body[id] = document
    end
    self
  end

  def update(document={})
    raise Goliath::Validation::Error.new(400, "Must provide a topic to update") if topic.blank?
    find
    if id.blank?
      self.body ||= {}
      self.body.deep_merge!(document)
      mongo_query(collection, :update, {_id: topic}, self.body.merge(_id: topic), {upsert: true})
      self.body
    else
      self.body     ||= {}
      self.body[id] ||= {}
      self.body[id].deep_merge!(document)
      update = Hash[document.map { |key, value| [[id, key].map(&:to_s).join('.'), value] }].merge(_id: topic)
      mongo_query(collection, :update, {_id: topic}, {'$set' => update} , {upsert: true})
      self.body[id]
    end
  end

  def destroy
    raise Goliath::Validation::Error.new(400, "Must provide a topic to destroy") if topic.blank?
    if id.blank?
      mongo_query(collection, :delete, {:_id => topic})
      {topic: topic}
    else
      mongo_query(collection, :update, {:_id => topic}, {'$unset' => { id => 1}})
      {topic: topic, id: id}
    end
  end

  def topic= t
    @topic = self.class.format_id(t) if t.present?
  end

  protected

  def collection_name
    [organization.to_s, 'config'].join('.')
  end

end
