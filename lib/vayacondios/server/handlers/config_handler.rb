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
      raise Vayacondios::Error::BadRequest.new unless options[:topic] && options[:id]
      raise Vayacondios::Error::BadRequest.new if /\W/ =~ options[:id]
      
      existing_document = ConfigDocument.find(@mongo, options)
      if existing_document
        existing_document.update(document)
      else
        existing_document = ConfigDocument.create(@mongo, document, options)
      end
    end

    def self.find(mongodb, options)
      existing_document = ConfigDocument.find(mongodb, options)
      raise Vayacondios::Error::NotFound.new unless existing_document
      existing_document
    end
  end
end
