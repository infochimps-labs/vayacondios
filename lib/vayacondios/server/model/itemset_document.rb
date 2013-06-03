require 'vayacondios/server/model/document'
require 'vayacondios/server/legacy_switch'

# The configuration model
#
# Configuration documents are key-value pairs, represented in JSON. A document
# consists of a primary key called the topic (_id in mongodb). It belongs to a
# collection named "#{organization_name}.config"
#
# Note: mongodb is passed in beacuse Goliath makes Thread lookups will not
# work while Goliath is in a streaming context.

class Vayacondios::ItemsetDocument < Vayacondios::Document
  attr_reader :organization, :topic, :id

  def initialize(mongodb, options = {})
    super options
    @mongo = mongodb
    options = sanitize_options(options)
    @id = options[:id]

    @body         = nil
    @mongo        = mongodb

    @handler = Vayacondios.legacy_switch

    collection_name = [organization.to_s, topic, 'itemset'].join('.')
    @collection = @mongo.collection(collection_name)
  end

  def self.create(mongodb, document, options={})
    self.new(mongodb, options).update(document)
  end

  def self.find(mongodb, options={})
    self.new(mongodb, options).find
  end

  def body
    @handler.wrap_contents(@body)
  end

  def find
    result = @collection.find_one({_id: @id})

    if result
      result.delete("_id")
      @body = result["d"]
      self
    else
      nil
    end
  end

  def update(document)
    raise Vayacondios::Error::BadRequest.new unless @handler.proper_request(document)

    @body = extract_contents(document)


    @collection.update({:_id => @id}, {:_id => @id, 'd' => @body }, {upsert: true})
    
    self
  end

  def patch(document)
    raise Vayacondios::Error::BadRequest.new unless @handler.proper_request(document)

    # Merge ourselves
    if @body
      @body = @body + extract_contents(document)
    else
      @body = extract_contents(document)
    end

    @collection.update({:_id => @id}, {
      '$addToSet' => {
        'd' => {
          '$each'=> extract_contents(document)
        }
      }
    }, {upsert: true})
    
    self
  end

  def destroy(document)
    raise Vayacondios::Error::BadRequest.new unless @handler.proper_request(document)

    @body -= extract_contents(document)
    
    @collection.update({:_id => @id}, {
      '$pullAll' => {
        'd' => extract_contents(document)
      }
    })
    
    self
  end

  protected

  def extract_contents(document)
    puts "doc = #{document}. contents = #{result = @handler.extract_contents(document)}"
    result
  end

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
