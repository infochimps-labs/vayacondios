class Vayacondios
  class EventHandler < Hash
    TIMESTAMP_RE = /^\d+(?:\.\d+)?$/

    def self.get(options)
      sanitize_options!(options)

      topic        = options[:topic]
      id           = options[:id]
      organization = options[:organization]

      bucket       = bucket(organization, topic)
      collection   = collection(bucket)

      result = collection.find_one({_id: id})

      if result
        result["_timestamp"] = result.delete("t")
        result.merge!(result.delete("d")) if result["d"].present?
        self.new(result, options)
      end
    end

    attr_reader :organization, :topic
    def initialize(document, options={})
      self.class.sanitize_options!(options)
      self.class.symbolize_keys!(document)

      @options       = options
      @organization  = options[:organization]
      @topic         = options[:topic]

      document[:_id] = options[:id] if options[:id].present?

      id = document[:_id]
      document[:_id] = self.class.format_id(id) if id.present?

      self.replace(document)
    end

    def update
      bucket     = self.class.bucket(organization, topic)
      collection = self.class.collection(bucket)

      document = to_mongo

      if (id = document.delete(:_id)).present?
        collection.update({:_id => id}, document, {upsert: true})
      else
        collection.insert(document)
      end
    end

  private

      def to_mongo
        document  = { d: self.dup }
        id        = document[:d].delete(:_id)

        timestamp = document[:d].delete(:_timestamp) || Time.now.to_f

        raise ArgumentError, "Invalid _timestamp in seconds" unless timestamp.to_s.match(TIMESTAMP_RE)
        timestamp = Time.at(timestamp.to_f)

        document[:t]   = timestamp
        document[:_id] = id

        document
      end

      def self.format_id(id)
        if (id.is_a?(Hash) && id["$oid"].present?)
          id = BSON::ObjectId(id["$oid"])
        else
          id = id.to_s.gsub(/\W/,'')
          id = BSON::ObjectId(id) if id.match(/^[a-f0-9]{24}$/)
        end
      end

      def self.symbolize_keys!(hash)
        hash.keys.each do |key|
          obj = hash.delete(key)
          symbolize_keys!(obj) if obj.is_a?(Hash)
          hash[(key.to_sym rescue key) || key] = obj
        end
      end

      def self.sanitize_options!(options)
        symbolize_keys!(options)

        topic = options[:topic].gsub(/\W+/, '_')
        id    = format_id(options[:id])

        options.merge!(topic: topic, id: id)
      end

      def self.bucket(organization, topic)
        [organization, topic, 'events'].join('_')
      end

      def self.collection(bucket)
        env.mongo.collection(bucket)
      end
  end
end