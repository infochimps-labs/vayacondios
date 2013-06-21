class Vayacondios

  # Generic handler for documents stored in MongoDB.
  #
  # @attr [Mongo::Database] database the MongoDB database to use
  class MongoDocumentHandler < DocumentHandler

    attr_accessor :database

    # Create a new MongoDocumentHandler.
    #
    # @param [Logger] log
    # @param [Mongo::Database] database
    def initialize(log, database)
      super(log)
      self.database = database
    end
  end
end


