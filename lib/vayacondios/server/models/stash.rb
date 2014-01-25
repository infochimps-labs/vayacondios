# Stashes are documents with arbitrary key/value data.
#
# An HTTP request which sets a new stash
#
# ```
# POST /v2/coca_cola/stash/campaigns
# { "creatives": [ "atx-jan-01", "bos-jan-01"], "test": false }
# ```
#
# would result in a document in the `coca_cola.stash` collection with
# the following structure:
#
# ```
# {
#   "_id": "campaigns",
#   "creatives": [ "atx-jan-01", "bos-jan-01"],
#   "test": false
# }
# ```
#
class Vayacondios::Server::Stash < Vayacondios::Server::Document

  # The default number of stashes returned when searching.
  LIMIT = 50

  # The default sort order when searching.
  SORT  = 'ascending'
  ORDER = '_id'

  # Returned as an acknowledgement of the request when there is no
  # better option (#destroy, #update_many, &c.)
  # OK = {ok: true}

  def self.default_query_options
    { limit: LIMIT, order: ORDER, sort: SORT } 
  end

  # Create a new Stash.
  #
  # Because of the way Goliath works, the `log` and `database` are
  # created way up inside the `Vayacondios::HttpServer` and have to be
  # passed down into this method at initialization time of an Stash.
  #
  # @param [Logger] log the logger instance to use
  # @param [Mongo::Database] database the MongoDB database this stash will be stored in
  # @param [Hash] params other parameters for this stash
  # @option params [String] organization the name of this stash's organization
  # @option params [String] topic the name of this stash's topic
  # @option params [String, BSON::ObjectId] :id the ID to use within this stash
  # def initialize(log, database, params={})
  #   super(log, database, params)
  #   self.collection = self.database.collection(collection_name)
  # end

  # The name of the collection this stash will store its data in.
  #
  # @return [String]
  def location
    [organization.to_s, 'stash'].join('.')
  end

  def document
    { _id: topic }.merge(body || {})
  end

  def from_document doc
    d = {}.tap do |d|
      d[:topic] = doc.delete(:_id)
      doc = nil if doc.empty?
      if body.nil?
        new_body = doc 
      else
        new_body = body.merge(doc || {})
      end     
      d[:body]  =  new_body
    end
    receive! d
    self
  end
  
  def external_document
    { topic: topic }.merge(body || {})
  end

  def prepare_search query
    filter = query.merge(_id: topic).compact
    receive!(filter: filter)
    self
  end

  def prepare_create document
    if document.is_a? Hash
      document.symbolize_keys!
      raise Error.new ':topic is a reserved key and cannot be used in a stash document' if document.has_key?(:topic)
    end    
    if id.blank?
      raise Error.new 'If not including an Id, the document must be a Hash' unless document.is_a? Hash
      receive!(body: document)
    else
      receive!(body: { id => document })
    end
    self
  end

  def prepare_find
    raise Error.new('Cannot find a stash without a topic') unless topic
    self
  end

  def prepare_destroy query
    filter = query.merge(_id: topic).compact
    receive!(filter: filter)
    self
  end
end
