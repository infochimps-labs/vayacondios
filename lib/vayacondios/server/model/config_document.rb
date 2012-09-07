require 'vayacondios/server/model/document'

# The configuration model
#
# Configuration documents are key-value pairs, represented in JSON. A document
# consists of a primary key called the topic (_id in mongodb). It belongs to a
# collection named "#{organization_name}.config"
#
# Note: mongodb is passed in beacuse Goliath makes Thread lookups will not
# work while Goliath is in a streaming context.

class Vayacondios::ConfigDocument < Vayacondios::Document
  attr_reader :organization, :topic, :body, :id

  def initialize(mongodb, options = {})
    super options
    @mongo = mongodb
    options = sanitize_options(options)
    @id = options[:id]

    @body         = nil
    @field        = options[:field] ||= options[:id]
    @mongo        = mongodb

    collection_name = [organization.to_s, 'config'].join('.')
    @collection = @mongo.collection(collection_name)
  end

  def self.create(mongodb, document, options={})
    self.new(mongodb, options).update(document)
  end

  def self.find(mongodb, options={})
    self.new(mongodb, options).find
  end

  def find
    result = @collection.find_one({_id: @topic})

    if result.present?
      result.delete("_id")
      @body = result
      # @body = @field.split('.').inject(result){|acc, attr| acc = acc[attr]} if @field.present?
      self
    else
      nil
    end
  end

  def update(document)
    raise Error::BadRequest.new if !document.is_a?(Hash)

    # Merge ourselves
    document = body.deep_merge(document) if body

    fields = document
    # fields = {@field => document} if @field.present?

    @body = document
    @collection.update({:_id => @topic}, {'$set' => fields}, {upsert: true})

    self
  end

  def destroy(document)
    super
  end

  protected

  def sanitize_options(options)
    options = options.symbolize_keys

    topic = options[:topic]

    if (topic.is_a?(Hash) && topic["$oid"].present?)
      topic = BSON::ObjectId(topic["$oid"])
    elsif topic.is_a?(String)
      topic = topic.gsub(/\W/,'')
      if topic.to_s.match(/^[a-f0-9]{24}$/)
        topic = BSON::ObjectId(topic)
      end
    end

    field = options[:field].gsub(/\W/, '') if options[:field].present?

    options.merge(topic: topic, field: field)
  end
end
