require 'vayacondios/server/model/document'

# The event model
#
# Event documents are key-value pairs, represented in JSON. A document
# consists of a primary key called the topic (_id in mongodb). It belongs to a
# collection named "#{organization_name}.#{topic}.events"
#
# Note: mongodb is passed in beacuse Goliath makes Thread lookups will not
# work while Goliath is in a streaming context.

class Vayacondios::EventDocument < Vayacondios::Document
  attr_reader :organization, :topic, :body

  def initialize(mongodb, options = {})
    super options
    @mongo = mongodb
    options = sanitize_options(options)

    @body   = nil
    @id     = format_id(options[:id])
    @mongo  = mongodb

    collection_name = [organization, topic, 'events'].join('.')
    @collection = @mongo.collection(collection_name)
  end

  def self.create(mongodb, document, options={})
    self.new(mongodb, options).update(document)
  end

  def self.find(mongodb, options={})
    self.new(mongodb, options).find
  end

  def find
    result = @collection.find_one({_id: @id})
    if result.present?
      result.delete("_id")
      result['_timestamp'] = result.delete("t")
      result.merge! result.delete("d") if result["d"].present?
      @body = result
      self
    else
      nil
    end
  end

  def update(document)
    document = to_mongo(document)

    @body = document[:d]
    if @id
      @collection.update({:_id => @id}, document, {upsert: true})
    else
      @collection.insert(document)
    end

    self
  end

  def destroy(document)
    super
  end

  protected

  def sanitize_options(options)
    options = options.symbolize_keys

    topic = options[:topic].gsub(/\W+/, '_')
    id = format_id options[:id]

    options.merge!(topic: topic, id: id)
  end

  def format_id(id)
    if (id.is_a?(Hash) && id["$oid"].present?)
      id = BSON::ObjectId(id["$oid"])
    else
      id = id.to_s.gsub(/\W/,'')
      id = BSON::ObjectId(id) if id.match(/^[a-f0-9]{24}$/)
    end
    id
  end

  def to_mongo(document)
    {}.tap do |result|
      result[:d] = document.dup
      result[:_id] = @id if @id
      result[:t] = document.delete(:_timestamp) || Time.now
    end
  end
end
