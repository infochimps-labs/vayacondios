def mongo_connection
  @mongo_connection ||= Mongo::Connection.new(Settings[:mongo][:host],Settings[:mongo][:port])
end

def mongo_query &block
  yield mongo_connection.db(Settings[:mongo][:database])
end

def clean_mongo!
  mongo_query do |db|
    db.collections.select {|c| c.name !~ /^system/ }.each { |c| c.drop }
  end
end

RSpec.configure do |config|
  config.before :each do
    clean_mongo!
  end

  config.after :all do
    clean_mongo!
  end
end
