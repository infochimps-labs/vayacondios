# Vayacondios::ConfigHandler
#
# This handler will accept requests to update config for an organization. All
# updates will merge with an existing document.

class Vayacondios

  class ConfigHandler < DocumentHandler

    def find options={}
      super(options)
      (ConfigDocument.find(log, mongo, options) or raise Goliath::Validation::Error.new(404, "No config for /#{options[:topic]}/#{options[:id]}")).body
    end

    def create(options={}, document={})
      super(options, document)
      ConfigDocument.create(log, mongo, options, document)
    end

    def update(options={}, document={})
      super(options, document)
      ConfigDocument.update(log, mongo, options, document)
    end

    def patch options={}, document={}
      super(options, document)
      ConfigDocument.patch(log, mongo, options, document)
    end

    def delete options={}
      super(options)
      ConfigDocument.destroy(log, mongo, options)
    end

  end
end
