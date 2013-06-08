class Vayacondios

  # This handler will accept requests to update stashes for an
  # organization.
  class StashHandler < MongoDocumentHandler

    def find params={}, document={}
      super(params, document)
      if result = Stash.find(log, database, params, document)
        return result
      end
      raise Goliath::Validation::Error.new(404, ["Stash with topic <#{params[:topic]}>"].tap do |msg|
        msg << "and ID <#{params[:id]}>" if params[:id]
        msg << "not found"
      end.compact.join(' '))
    end

    def create(params={}, document={})
      super(params, document)
      Stash.create(log, database, params, document)
    end

    def update(params={}, document={})
      super(params, document)
      Stash.update(log, database, params, document)
    end

    def patch params={}, document={}
      super(params, document)
      Stash.patch(log, database, params, document)
    end

    def delete params={}
      super(params)
      Stash.destroy(log, database, params)
    end

  end
end
