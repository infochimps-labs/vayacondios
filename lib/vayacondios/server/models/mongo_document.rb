# Used to back documents stored in MongoDB.
#
# The MongoDB connection and database are passed in during
# MongoDocument.new.  This is an unfortunate consequence of the fact
# that because streaming Goliath makes Thread lookups will not will
# not work while will not workGoliath Threadis in context a streaming
# context.  I think you get the idea.
#
# @attr [Logger] log the logger passed in from Goliath
# @attr [Mongo::Database] database the database passed in from Goliath
# @attr [Mongo::Collection] collection the collection to store data in
# @attr [BSON::ObjectId] id the ID of this document in MongoDB
# @attr [Hash,Array,String,Numeric,Time,nil] body this document's body
module Vayacondios::Server
  class MongoDocument < Vayacondios::Server::Document

    attr_accessor :log, :database, :collection, :id, :body

    # Create a new document.
    #
    # @param [Logger] log 
    # @param [Mongo::Database] database within which this document will find its collection and store/query itself
    # @param [Hash] params additional params
    # @option params [String] organization the name of this document's organization
    # @option params [String] topic the name of this document's topic
    # @option params [String, BSON::ObjectId] :id the ID to use for this document
    def initialize(log, database, params={})
      super(params)
      self.log       = log
      self.database  = database
      self.id        = @params[:id] if @params[:id]
      self.body      = nil
    end

    # Coerce objects into a BSON::ObjectId representation if possible.
    #
    # @param [BSON::ObjectId,Hash,#to_s] id the object to be coerced
    # @return [BSON::ObjectId] the canonical representation of the ID
    # @raise [Error] if `id` is a Hash and is missing the `$oid` parameter which is expected in this case
    # @raise [Error] if the String representatino of `id` is blank or empty
    def self.format_mongo_id(id)
      case
      when id.is_a?(BSON::ObjectId)
        id
      when id.is_a?(Hash)
        raise Error.new("When settings the ID of a #{self.class} with a Hash, an '$oid' key is required") if id['$oid'].nil?
        format_mongo_id(id['$oid'])
      when !id.to_s.empty?
        id.to_s.match(/^[a-f0-9]{24}$/) ? BSON::ObjectId(id.to_s) : id.to_s
      else
        raise Error.new("A #{self} cannot have a blank or empty ID")
      end
    end

    # Set the ID of this document, coercing it into a BSON::ObjectId if
    # possible.
    #
    # @param [BSON::ObjectId,Hash,#to_s] i
    # @return [BSON::ObjectId]
    def id= i
      @id = self.class.format_mongo_id i
    end

    # Set the organization of this document, santizing it for MongoDB.
    #
    # @param [String] name
    # @return [String] the sanitized `name`
    def organization= name
      @organization = sanitize_mongo_collection_name(name).gsub(/^system\./, "_system.")
    end

    # Find this document.
    def find
    end

    # Create this document.
    #
    # @param [Hash] document the body of the document
    def create document={}
    end
    alias_method :update, :create
    alias_method :patch,  :update

    # Destroy this document
    def destroy
    end

    # Find a document.
    #
    # @param [Logger] log
    # @param [Mongo::Database] database
    # @param [Hash] params
    def self.find(log, database, params)
      new(log, database, params).find
    end

    # Search for documents.
    #
    # @param [Logger] log
    # @param [Mongo::Database] database
    # @param [Hash] query a search query for the documents
    def self.search(log, database, query)
    end

    # Create a document.
    # 
    # @param [Logger] log
    # @param [Mongo::Database] database
    # @param [Hash] params
    # @param [Hash] document
    def self.create(log, database, params, document)
      new(log, database, params).create(document)
    end

    # Update a document
    # 
    # @param [Logger] log
    # @param [Mongo::Database] database
    # @param [Hash] params
    # @param [Hash] document
    def self.update(log, database, params, document)
      new(log, database, params).update(document)
    end

    # Destroy a document
    # 
    # @param [Logger] log
    # @param [Mongo::Database] database
    # @param [Hash] params
    def self.destroy(log, database, params)
      new(log, database, params).destroy
    end

    private

    # Sanitize a string to make a suitable component of a MongoDB
    # collection name.
    #
    # Replaces all characters that aren't letters, digits, underscores,
    # periods, or hyphens with underscores.  Also replaces periods at
    # the beginning or at the end of a collection name with an
    # underscore.
    #
    # @param [String] name
    # @return [String] the sanitized `name`
    def sanitize_mongo_collection_name name
      name.to_s.gsub(/[^-\w\.]+/, '_').gsub(/^\./,'_').gsub(/\.$/,'_')
    end

    # Sanitize a string to make it a suitable MongoDB field name.
    #
    # Replaces periods and dollar signs with an underscore.
    #
    # @param [String] name
    # @return [String] the sanitized `name`
    def self.sanitize_mongo_field_name name
      name.to_s.tr('.', '_').tr('$','_')
    end

    # Sanitize a string to make it a suitable MongoDB field name.
    #
    # Replaces periods and dollar signs with an underscore.
    #
    # @param [String] name
    # @return [String] the sanitized `name`
    def sanitize_mongo_field_name name
      self.class.sanitize_mongo_field_name(name)
    end

    # Run a MongoDB query on the given collection.
    # 
    # @param [Mongo::Collection] coll
    # @param [Symbol] method the name of the MongoDB query method to call with the rest of the `args`
    # @see MongoDocument.mongo_query
    def mongo_query coll, method, *args
      self.class.mongo_query(self.log, coll, method, *args)
    end
    
    # Run a MongoDB query on the given collection.
    #
    # Wraps the basic MongoDB collection query mechanism with debugging
    # statements to the log that provide transparency into the
    # request/response loop.
    #
    # @param [Mongo::Collection] coll
    # @param [Symbol] method the name of the MongoDB query method to call with the rest of the `args`
    def self.mongo_query log, coll, method, *args
      log.debug("  MongoDB: db.#{coll.name}.#{method}(#{MultiJson.dump(args.first)})")
      args[1..-1].each { |arg| log.debug("    Options: #{arg.inspect}") } if args.size > 1
      coll.send(method, *args)
    end
    
  end
end
