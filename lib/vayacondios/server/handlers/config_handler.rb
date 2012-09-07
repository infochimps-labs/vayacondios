# Vayacondios::ConfigHandler
#
# This handler will accept requests to update config for an organization. All
# updates will merge with an existing document.

class Vayacondios

  class ConfigHandler

    def initialize(mongodb)
      @mongo = mongodb
    end

    def update(document, options={})
      raise Error::BadRequest.new unless options[:topic] && options[:id]
      raise Error::BadRequest.new if /\W/ =~ options[:id]
      
      existing_document = ConfigDocument.find(@mongo, options)
      if existing_document
        existing_document.update(document)
      else
        existing_document = ConfigDocument.create(@mongo, document, options)
      end

      {
        topic: existing_document.topic,
        id: existing_document.id,
        cargo: existing_document.body,
        status: :success
      }
    end

    def self.find(mongodb, options)
      existing_document = ConfigDocument.find(mongodb, options)
      return nil unless existing_document
      existing_document.body
    end
  end
end