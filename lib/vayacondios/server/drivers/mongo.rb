module Vayacondios::Server
  class MongoDriver
    include Driver

    def self.connect(options = {})
      new(options)
    end

    def initialize(options = {})
      @log = options[:log]
      mongo = EM::Mongo::Connection.new(options[:host], options[:port], 1, reconnect_in: 1)
      @connection = mongo.db options[:name]
    end

    def connection
      @connection.collection location
    end

    # Coerce objects into a BSON::ObjectId representation if possible.
    #
    # @param [BSON::ObjectId,Hash,#to_s] id the object to be coerced
    # @return [BSON::ObjectId] the canonical representation of the ID
    # @raise [Error] if `id` is a Hash and is missing the `$oid` parameter which is expected in this case
    # @raise [Error] if the String representation of `id` is blank or empty
    def format_id id
      case
      when id.is_a?(BSON::ObjectId)
        id
      when id.is_a?(Hash)
        raise Error.new("When settings the ID of a #{self.class} with a Hash, an '$oid' key is required") if id['$oid'].nil?
        format_id(id['$oid'])
      when !id.to_s.empty?
        id.to_s.match(/^[a-f0-9]{24}$/) ? BSON::ObjectId(id.to_s) : id.to_s
      else
        raise Error.new("A #{self} cannot have a blank or empty ID")
      end
    end

    def mongo_prepare doc
      doc[:_id] = format_id(doc[:_id]) if doc[:_id]
      doc
    end

    def mongo_unprepare doc
      doc['_id'] = doc['_id'].to_s
      doc.symbolize_keys
    end

    def selector query
      sel = { }.tap do |sel|
        time = query.delete(:_t)
        sel[:_t] = time.inject({}){ |t, (k,v)| t[('$' + k.to_s).to_sym] = v ; t } if time
        data = query.delete(:_d)
        sel.merge! to_dotted_hash(_d: data)
      end
      query.merge(sel).compact_blank
    end

    def to_dotted_hash(hsh, key_string = '')
      hsh.each_with_object({}) do |(k, v), ret|
        key = key_string + k.to_s
        if v.is_a? Hash
          ret.merge! to_dotted_hash(v, key + '.')
        else
          ret[key] = v
        end
      end
    end
    
    def projector query
      if query[:sort] == 'time'
        query[:sort] = '_t'
      elsif query[:sort].present?
        query[:sort] = '_d.' + query[:sort]
      end
      query[:_reverse] if query.delete(:order) == 'descending'
      query
    end

    def search(request, filter, opts)
      select = selector(filter)
      log.debug "    Selector doc: #{select}"
      project = projector(opts)
      log.debug "    Projector doc: #{project}"
      res = connection.find(select, project) || []
      log.debug "      Result: #{res}"
      res.map{ |res| mongo_unprepare res }
    end

    def insert request
      mongo_doc = mongo_prepare request
      log.debug "    Mongo doc: #{mongo_doc}"
      res = connection.save mongo_doc
      log.debug "      Result: #{res}"
      res = mongo_doc[:_id] if res == true
      { _id: format_id(res).to_s }
    end

    def retrieve request
      mongo_doc = mongo_prepare request
      log.debug "    Mongo doc: #{mongo_doc}"
      res = connection.find_one mongo_doc
      log.debug "      Result: #{res}"
      return nil if res.nil?
      mongo_unprepare res
    end

    def remove(request, filter)
      mongo_doc = mongo_prepare(request)
      mongo_doc.merge! selector(filter)
      log.debug "    Mongo doc: #{mongo_doc}"
      res = connection.remove mongo_doc
      log.debug "      Result: #{res}"
      nil
    end

    # for testing only
    def reset!
      connection.drop
    end

    def count
      connection.count
    end
  end
end
