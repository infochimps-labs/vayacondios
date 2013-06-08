# Vayacondios::EventHandler
#
# This handler will accept Events for an organization via its #update
# method.
class Vayacondios

  class EventHandler < MongoDocumentHandler

    def find params={}, document={}
      super(params, document)
      if result = Event.find(log, database, params, document)
        return result
      else
        raise Goliath::Validation::Error.new(404, "Event with topic <#{params[:topic]}> and ID <#{params[:id]}> not found")
      end
    end
    
    def create(params={}, document={})
      super(params, document)
      Event.create(log, database, params, document)
    end

    def update(params={}, document={})
      super(params, document)
      raise Goliath::Validation::Error.new(400, "Cannot update events")
    end
    
    def patch params={}, document={}
      super(params, document)
      raise Goliath::Validation::Error.new(400, "Cannot patch events")
    end

    def delete params={}
      super(params)
      raise Goliath::Validation::Error.new(400, "Cannot delete events")
    end
    
  end
end
