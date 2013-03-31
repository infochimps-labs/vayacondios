# Used to back documents stored in MongoDB.
#
# The MongoDB connection and database are passed in during
# MongoDocument.new.  This is because Goliath makes Thread lookups
# will not work while Goliath is in a streaming context.
#
class Vayacondios::MongoDocument < Vayacondios::Document

  attr_accessor :log, :mongo, :collection, :id, :timestamp, :body

  def initialize(log, mongodb, options={})
    super(options)
    self.log       = log
    self.mongo     = mongodb
    self.id        = options[:id]
    self.timestamp = options[:timestamp]
    self.body      = nil
  end

  def self.format_id(id)
    case
    when id.is_a?(BSON::ObjectId)
      id
    when (id.is_a?(Hash) && id["$oid"].present?)
      BSON::ObjectId(id["$oid"])
    when !id.to_s.empty?
      id = id.to_s.gsub(/\W/,'')
      id.match(/^[a-f0-9]{24}$/) ? BSON::ObjectId(id) : id
    else
      id
    end
  end

  def id= i
    @id = self.class.format_id i
  end

  def find
  end

  def create
  end
  alias_method :update, :create
  alias_method :patch,  :update

  def destroy
  end
  
  def self.find(log, mongodb, options)
    new(log, mongodb, options).find
  end
  
  def self.create(log, mongodb, options, document)
    new(log, mongodb, options).create(document)
  end
  
  def self.update(log, mongodb, options, document)
    new(log, mongodb, options).update(document)
  end

  def self.patch(log, mongodb, options, document)
    new(log, mongodb, options).patch(document)
  end

  def self.destroy(log, mongodb, options)
    new(log, mongodb, options).destroy
  end
  
  def mongo_query coll, method, *args
    log.debug("  MongoDB: db.#{coll.name}.#{method}(#{MultiJson.dump(args.first)})")
    args[1..-1].each { |arg| log.debug("    Options: #{arg.inspect}") } if args.size > 1
    coll.send(method, *args)
  end
  
end
