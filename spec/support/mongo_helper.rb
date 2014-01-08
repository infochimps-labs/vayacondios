module MongoHelper
  def mongo_connection
    @mongo_connection ||= Mongo::Connection.new(Settings[:database][:host], Settings[:database][:port])
  end

  def mongo_query(&blk)
    yield mongo_connection.db(Settings[:database][:name])
  end

  def clean_mongo!
    mongo_query do |db|
      db.collections.select{ |c| c.name !~ /^system/ }.each{ |c| c.drop }
    end
  end
end
