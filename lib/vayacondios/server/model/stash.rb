# Stashes are key-value pairs.  In additional to the `organization`
# and `topic` properties of the Document class they can be created
# with arbitrary key-value data.
#
# Stashes are stored in MongoDB:
#
#   * the collection will be "#{organization}.stash"
#   * the `topic` of the stash will be used as the `_topic` of the corresponding MongoDB document
#   * all other key-value data will be stored within the corresponding MongoDB document
#
class Vayacondios::Stash < Vayacondios::MongoDocument

  LIMIT = 200
  SORT  = ['_id', 'ascending']

  def initialize(log, database, params={})
    super(log, database, params)
    self.collection = self.database.collection(collection_name)
  end

  def collection_name
    [organization.to_s, 'stash'].join('.')
  end
  
  def id= i
    @id = i.to_s if i.present?
  end

  def topic= t
    if t.nil?
      @topic = nil
    else
      @topic = self.class.format_mongo_id(t) if t.present?
    end
  end

  def find query={}
    case
    when topic.blank? && id.blank?
      return search(query)
    when id.blank?
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
    self.body
  end

  def search(query={})
    limit = (query.delete("limit") || LIMIT).to_i
    sort  = (query.delete("sort")  || SORT)
    mongo_query(collection, :find, query, sort: sort, limit: limit)
  end

  def create document={}
    if id.blank?
      raise Goliath::Validation::Error.new(400, "If not including an _id the document must be a Hash") unless document.is_a?(Hash)
      mongo_query(collection, :update, {:_id => topic}, document.merge(_id: topic), {upsert: true})
    else
      mongo_query(collection, :update, {:_id => topic}, {'$set' => {id => document}}, {upsert: true})
    end
    self.body = document
  end

  def update(document={})
    find
    if id.blank?
      raise Goliath::Validation::Error.new(400, "If not including an _id the document must be a Hash") unless document.is_a?(Hash)
      self.body = {} unless self.body.is_a?(Hash)
      self.body.deep_merge!(document)
      mongo_query(collection, :update, {_id: topic}, self.body.merge(_id: topic), {upsert: true})
      self.body
    else
      mongo_query(collection, :update, {_id: topic}, {'$set' => to_mongo_update_document(document)} , {upsert: true})
      self.body
    end
  end

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
      raise Goliath::Validation::Error.new(400, "Cannot update using a document of class #{document.class}")
    end
  end
      
  def destroy
    if id.blank?
      mongo_query(collection, :delete, {:_id => topic})
      {topic: topic}
    else
      mongo_query(collection, :update, {:_id => topic}, {'$unset' => { id => 1}})
      {topic: topic, id: id}
    end
  end

end
