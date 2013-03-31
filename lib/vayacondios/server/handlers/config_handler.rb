# Vayacondios::ConfigHandler
#
# This handler will accept requests to update config for an organization. All
# updates will merge with an existing document.

class Vayacondios

  class ConfigHandler < DocumentHandler

    def find options={}
      super(options)
      ensure_topic_and_id(options)
      (ConfigDocument.find(log, mongo, options) or raise Goliath::Validation::Error.new(404, "No config for /#{options[:topic]}/#{options[:id]}")).body
    end

    def create(options={}, document={})
      super(options, document)
      ensure_topic_and_id(options)
      ConfigDocument.create(log, mongo, options, document)
    end

    def update(options={}, document={})
      super(options, document)
      ensure_topic_and_id(options)
      ConfigDocument.update(log, mongo, options, document)
    end

    def patch options={}, document={}
      super(options, document)
      ensure_topic_and_id(options)
      ConfigDocument.patch(log, mongo, options, document)
    end

    def delete options={}
      super(options)
      ensure_topic_and_id(options)
      ConfigDocument.destroy(log, mongo, options)
    end

    protected

    def ensure_topic_and_id(options={})
      raise Goliath::Validation::Error.new(400, "Cannot address a config without a 'topic'") unless options[:topic] && options[:id]
      raise Goliath::Validation::Error.new(400, "Cannot address a config without an 'id'")   unless options[:id]
      raise Goliath::Validation::Error.new(400, "A config 'id' must consist of lowercase letters, numbers, underscore, or hyphen") unless options[:id].to_s =~ IDENTIFIER_REGEXP
    end
    
  end
end
