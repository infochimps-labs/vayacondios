module DatabaseHelper
  def db_connection
    @db_connection ||= Mongo::Connection.new(Settings[:database][:host], Settings[:database][:port])
  end

  def db_query(&blk)
    yield db_connection.db(Settings[:database][:name])
  end

  def clean_db!
    db_query do |db|
      db.collections.select{ |c| c.name !~ /^system/ }.each{ |c| c.drop }
    end
  end
end
