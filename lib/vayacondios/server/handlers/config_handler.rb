class Vayacondios
  class ConfigHandler < Hash
    def self.get(options)
      sanitize_options!(options)

      topic        = options[:topic]
      field        = options[:field] ||= options[:id]
      organization = options[:organization]

      bucket     = bucket(organization)
      collection = collection(bucket)


      fields = {'_id' => 0}
      fields[field] = 1 if field.present?

      result = collection.find_one({_id: topic}, {fields: fields})

      if result.present?
        result = field.split('.').inject(result){|acc, attr| acc = acc[attr]} if field.present?
        self.new(result, options)
      end
    end

    attr_reader :organization, :topic, :field
    def initialize(document, options={})
      self.class.sanitize_options!(options)

      @options      = options
      @organization = options[:organization]
      @topic        = options[:topic]
      @field        = options[:field]

      if !document.is_a?(Hash)
        document = {@field.split(/\W/).last.to_sym => document}
      end

      self.replace(document)
    end

    def update
      document = self

      bucket     = self.class.bucket(organization)
      collection = self.class.collection(bucket)

      if self.topic.present?
        existing_document = self.class.get(@options)
        document = existing_document.deep_merge(document) if existing_document.present?

        fields   = {field => document} if field.present?
        fields ||= document

        collection.update({:_id => topic}, {'$set' => fields}, {upsert: true})
      else
        @topic = collection.insert(document)
        document.delete(:_id)
      end

      {topic: self.topic, status: :success, cargo: document}
    end

  private

      def self.sanitize_options!(options)
        options.symbolize_keys!

        topic = options[:topic]

        if (topic.is_a?(Hash) && topic["$oid"].present?)
          topic = BSON::ObjectId(topic["$oid"])
        elsif topic.is_a?(String)
          topic = topic.gsub(/\W/,'')
          if topic.to_s.match(/^[a-f0-9]{24}$/)
            topic = BSON::ObjectId(topic)
          end
        end

        field = options[:field].gsub(/\W/, '') if options[:field].present?

        options.merge!(topic: topic, field: field)
      end

      def self.bucket(organization)
        [organization.to_s, 'config'].join('.')
      end

      def self.collection(bucket)
        env.mongo.collection(bucket)
      end
  end
end