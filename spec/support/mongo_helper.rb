module MongoHelper
  def mongo_connection
    @mongo_connection ||= Mongo::Connection.new(Settings[:mongo][:host], Settings[:mongo][:port])
  end

  def mongo_query(&blk)
    yield mongo_connection.db(Settings[:mongo][:database])
  end

  def clean_mongo!
    mongo_query do |db|
      db.collections.select{ |c| c.name !~ /^system/ }.each{ |c| c.drop }
    end
  end
end
