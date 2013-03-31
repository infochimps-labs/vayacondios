# Vayacondios::ConfigHandler
#
# This handler will accept requests to update config for an organization. All
# updates will merge with an existing document.

class Vayacondios

  class ConfigHandler < DocumentHandler

    def find options={}
      super(options)
      raise Goliath::Validation::Error.new(400, "Cannot find a config without a 'topic'") unless options[:topic]
      raise Goliath::Validation::Error.new(400, "Cannot find a config without an 'id'")   unless options[:id]
      (ConfigDocument.find(log, mongo, options) or raise Goliath::Validation::Error.new(404, "No config for /#{options[:topic]}/#{options[:id]}")).body
    end

    def create(options={}, document={})
      super(options, document)
      raise Goliath::Validation::Error.new(400, "Cannot create a config without a 'topic'") unless options[:topic] && options[:id]
      raise Goliath::Validation::Error.new(400, "Cannot create a config without an 'id'")   unless options[:id]
      raise Goliath::Validation::Error.new(400, "An 'id' cannot contain any whitespace")    if     options[:id] =~ /\W/
      ConfigDocument.create(log, mongo, options, document)
    end

    def update(options={}, document={})
      super(options, document)
      raise Goliath::Validation::Error.new(400, "Cannot update a config without a 'topic'") unless options[:topic] && options[:id]
      raise Goliath::Validation::Error.new(400, "Cannot update a config without an 'id'")   unless options[:id]
      raise Goliath::Validation::Error.new(400, "An 'id' cannot contain any whitespace")    if     options[:id] =~ /\W/
      ConfigDocument.update(log, mongo, options, document)
    end

    def patch options={}, document={}
      super(options, document)
      raise Goliath::Validation::Error.new(400, "Cannot patch a config without a 'topic'") unless options[:topic] && options[:id]
      raise Goliath::Validation::Error.new(400, "Cannot patch a config without an 'id'")   unless options[:id]
      raise Goliath::Validation::Error.new(400, "An 'id' cannot contain any whitespace")    if     options[:id] =~ /\W/
      ConfigDocument.patch(log, mongo, options, document)
    end

    def delete options={}
      super(options)
      ConfigDocument.destroy(log, mongo, options)
    end
    
  end
end
