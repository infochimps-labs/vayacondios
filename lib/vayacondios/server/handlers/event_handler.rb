# Vayacondios::EventHandler
#
# This handler will accept requests to update Event for an organization. All
# updates will overwrite an existing document.

class Vayacondios

  class EventHandler

    def initialize(mongodb)
      @mongo = mongodb
    end

    def update(document, options={})
      raise Error::BadRequest.new unless options[:topic]
      raise Error::BadRequest.new if options[:id] && /\W/ =~ options[:id]

      existing_document = EventDocument.find(@mongo, options)
      if existing_document
        existing_document.update(document)
      else
        existing_document = EventDocument.create(@mongo, document, options)
      end
      existing_document.body
    end

    def self.find(mongodb, options)
      existing_document = EventDocument.find(mongodb, options)
      return nil unless existing_document
      existing_document.body
    end
  end
end