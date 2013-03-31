# ConfigDocuments are key-value paris.  In additional to the
# `organization` and `topic` properties of the Document class they can
# be created with arbitrary key-value data.
#
# Configuration documents are currently stored in MongoDB:
#
#   * the collection will be "#{organization}.config"
#   * the `topic` of the config will be used as the `_id` of the corresponding MongoDB document
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
    raise Goliath::Validation::Error.new(400, "Cannot find a config without an ID") if id.blank?
    result = mongo_query(collection, :find_one, {_id: topic}, {fields: [id]})
    if result.present? && result.has_key?(id)
      result.delete("_id")
      self.body = result[id]
      # @body = @field.split('.').inject(result){|acc, attr| acc = acc[attr]} if @field.present?
      self
    else
      nil
    end
  end

  def create document={}
    raise Goliath::Validation::Error.new(400, "Must provide a topic to update") if topic.blank?
    raise Goliath::Validation::Error.new(400, "Must provide an ID to update") if id.blank?
    self.body = {} unless self.body
    self.body[id] = document
    mongo_query(collection, :update, {:_id => topic}, {'$set' => {id => document}}, {upsert: true})
    self.body[id]
  end

  def update(document={})
    raise Goliath::Validation::Error.new(400, "Must provide a topic to patch") if topic.blank?
    raise Goliath::Validation::Error.new(400, "Must provide an ID to patch") if id.blank?
    self.body = {} unless self.body
    self.body[id] ||= {}
    self.body[id].deep_merge!(document)
    update = Hash[document.map { |key, value| [[id, key].map(&:to_s).join('.'), value] }]
    mongo_query(collection, :update, {:_id => topic}, {'$set' => update} , {upsert: true})
    self.body[id]
  end

  def destroy
    raise Goliath::Validation::Error.new(400, "Must provide a topic to destroy") if topic.blank?
    raise Goliath::Validation::Error.new(400, "Must provide an ID to destroy") if id.blank?
    mongo_query(collection, :update, {:_id => topic}, {'$unset' => { id => 1}})
    {id: self.id}
  end

  def topic= t
    @topic = self.class.format_id(t) if t.present?
  end

  protected

  def collection_name
    [organization.to_s, 'config'].join('.')
  end

end
