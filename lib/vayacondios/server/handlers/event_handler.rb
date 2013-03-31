# Vayacondios::EventHandler
#
# This handler will accept Events for an organization via its #update
# method.
class Vayacondios

  class EventHandler < DocumentHandler

    def find options={}
      super(options)
      raise Goliath::Validation::Error.new(400, "Cannot find an event without a 'topic'") unless options[:topic]
      raise Goliath::Validation::Error.new(400, "Cannot find an event without an 'id'") unless options[:id]
      (EventDocument.find(log, mongo, options) or raise Goliath::Validation::Error.new(404, "No event with ID /#{options[:topic]}/#{options[:id]}")).body
    end
    
    def create(options={}, document={})
      super(options, document)
      raise Goliath::Validation::Error.new(400, "Cannot create an event without a 'topic'") unless options[:topic]
      raise Goliath::Validation::Error.new(400, "IDs can only contain lowercase letters, numbers, or underscores") if options[:id] && options[:id] =~ /\W/
      { id: EventDocument.create(log, mongo, options, document).id }
    end

    def update(options={}, document={})
      super(options, document)
      raise Goliath::Validation::Error.new(400, "Cannot update an event without a 'topic'") unless options[:topic]
      raise Goliath::Validation::Error.new(400, "Cannot update an event without an 'id'")   unless options[:id]
      raise Goliath::Validation::Error.new(400, "IDs can only contain lowercase letters, numbers, or underscores") if options[:id] =~ /\W/
      { id: EventDocument.update(log, mongo, options, document).id }
    end
    
    def patch options={}, document={}
      super(options, document)
      raise Goliath::Validation::Error.new(400, "Cannot patch events")
    end

    def delete options={}
      super(options)
      raise Goliath::Validation::Error.new(400, "Cannot delete events")
    end
    
  end
end
