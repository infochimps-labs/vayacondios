class Vayacondios
  class MongoDocumentHandler < DocumentHandler

    attr_accessor :database
    
    def initialize(log, database)
      super(log)
      self.database = database
    end
  end
end


