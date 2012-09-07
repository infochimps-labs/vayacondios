# Vayacondios::ItemsetHandler
#
# This handler will accept requests to handle arrays for an organization.
# These arrays can only contain numbers and strings.
#  GET requests are idempotent
#  POST requests are forbidden
#  PUT requests will clobber an existing array
#  DELETE requests require an array of objects to remove

class Vayacondios

  class ItemsetHandler

    def initialize(mongodb)
      @mongo = mongodb
    end

    def update(document, options={})
      validate_options options

      existing_document = ItemsetDocument.find(@mongo, options)
      if existing_document
        existing_document.update(document)
      else
        existing_document = ItemsetDocument.create(@mongo, document, options)
      end
    end
    
    def patch(document, options={})
      validate_options options

      existing_document = ItemsetDocument.find(@mongo, options)
      if existing_document
        existing_document.patch(document)
      else
        existing_document = ItemsetDocument.create(@mongo, document, options)
      end
    end
    
    def destroy(document, options={})
      validate_options options
      
      existing_document = ItemsetDocument.find(@mongo, options)
      puts "destroy existing"
      existing_document.destroy(document)
    end

    def self.find(mongodb, options)
      existing_document = ItemsetDocument.find(mongodb, options)
      raise Error::NotFound.new unless existing_document
      existing_document
    end
    
    protected
    
    def validate_options(options)
      raise Error::BadRequest.new unless options[:topic] && options[:id]
      raise Error::BadRequest.new if /\W/ =~ options[:id]
    end
  end
end
