# Used to back documents stored in MongoDB.
#
# The MongoDB connection and database are passed in during
# MongoDocument.new.  This is because Goliath makes Thread lookups
# will not work while Goliath is in a streaming context.
#
class Vayacondios::MongoDocument < Vayacondios::Document

  attr_accessor :log, :database, :collection, :id, :body

  def initialize(log, database, params={})
    super(params)
    self.log       = log
    self.database  = database
    self.id        = @params[:id] if @params[:id]
    self.body      = nil
  end

  def self.format_mongo_id(id)
    case
    when id.is_a?(BSON::ObjectId)
      id
    when id.is_a?(Hash)
      raise Error.new("When settings the ID of a #{self.class} with a Hash, an '$oid' key is required") if id['$oid'].nil?
      format_mongo_id(id['$oid'])
    when !id.to_s.empty?
      id.to_s.match(/^[a-f0-9]{24}$/) ? BSON::ObjectId(id.to_s) : id.to_s
    else
      raise Error.new("A #{self} cannot have a blank or empty ID")
    end
  end

  def id= i
    @id = self.class.format_mongo_id i
  end

  def topic= name
    @topic = sanitize_mongo_collection_name(name)
  end

  def organization= name
    @organization = sanitize_mongo_collection_name(name)
  end

  def sanitize_mongo_collection_name name
    name.to_s.gsub(/[^\w\.]+/, '_').gsub(/^\./,'_').gsub(/\.$/,'_')
  end
  
  def find
  end

  def create document={}
  end
  alias_method :update, :create
  alias_method :patch,  :update

  def destroy
  end
  
  def self.find(log, database, params)
    new(log, database, params).find
  end
  
  def self.create(log, database, params, document)
    new(log, database, params).create(document)
  end
  
  def self.update(log, database, params, document)
    new(log, database, params).update(document)
  end

  def self.patch(log, database, params, document)
    new(log, database, params).patch(document)
  end

  def self.destroy(log, database, params)
    new(log, database, params).destroy
  end
  
  def mongo_query coll, method, *args
    log.debug("  MongoDB: db.#{coll.name}.#{method}(#{MultiJson.dump(args.first)})")
    args[1..-1].each { |arg| log.debug("    Options: #{arg.inspect}") } if args.size > 1
    coll.send(method, *args)
  end
  
end
