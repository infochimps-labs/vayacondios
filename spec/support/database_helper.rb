module DatabaseHelper

  def insert_record(index, document)
    # mongo only
    db_query(index){ |db| db.connection.insert(document) }
  end

  def database_count index
    # mongo only
    db_query(index){ |db| db.connection.count }
  end

  def retrieve_record(index, filter = {})
    # mongo only
    db_query(index){ |db| db.connection.find_one(filter) }
  end

  def db_connection
    return @db_connection if @db_connection
    settings = Vayacondios::Server::DbConfig.env :test
    driver = Vayacondios::Server::Driver.retrieve settings[:driver]
    @db_connection = driver.connect settings.merge(log: log)
  end

  def db_locations    
    @locations ||= [ "organization.topic.events", "organization.stash" ]
  end
  
  def db_query(location, &blk)
    db_connection.set_location location
    db_locations << location
    result = blk.call db_connection
    db_connection.unset_location
    result
  end

  def db_reset!
    db_locations.uniq.each do |location|
      db_query(location){ |db| EM::Synchrony.sync db.reset! }
    end
  end
end
