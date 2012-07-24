class HttpShim < Goliath::API
  class Version1 < Goliath::API
    def response(env, path_params={})
      if %w{PUT POST}.include?(env['REQUEST_METHOD'])
        post(path_params, env.params)
      elsif env['REQUEST_METHOD'] == 'GET'
        get(path_params)
      else
        [400, {}, {}]
      end
    end

  protected

      def post(path, params)
        bucket, id, field = parse_path(path)

        raise ArgumentError, "Must specify an organization and type in the path" unless bucket.present?
        raise ArgumentError, "Must specify a document in the path to update nested fields" if field.present? && !id.present?

        params = format_event(params) if path[:type] == 'event'
        result = insert(bucket, params.merge({_id: id}), field)

        [200, {}, { :result => { :bucket => bucket, :id => id||result.to_s }}]
      end

      def get(path)        
        bucket, id, field = parse_path(path)
        
        raise ArgumentError, "Must specify an organization and type in the path" unless bucket.present?
        raise ArgumentError, "Must specify a document id in the path" unless id.present?
        
        result = find(bucket, id, field)

        if result.present?
          result = unformat_event(result) if path[:type] == "event"
          
          [200, {}, result]
        else
          [404, {}, {error: 'Not Found'}]
        end
      end
      
    private
    
      def format_event(document)
        time = document.delete(:time) || document.delete("time")
        time = time ? Time.parse(time) : Time.now
        
        {t: time, d: document}
      end
      
      def unformat_event(record)
        record.delete("_id")
        time = record.delete('t')
        record["d"].merge("time" => time)
      end
      
      def parse_path(path)
        segments = path[:id].to_s.split('/').reject(&:blank?)

        id       = segments.shift
        field    = segments.join('.')
        
        if path[:type] == 'event'
          bucket = [path[:organization], id, 'events'].join('_')
          id     = segments.first
          field  = nil
        else
          bucket = [path[:organization], path[:type]].join('.')
        end
        
        id       = BSON::ObjectId(id) if id.to_s.match(/^[a-f0-9]{24}$/)
        
        [bucket, id, field]
      end
      
      def collection(bucket)
        collection = ::DB.collection(bucket)
      end
      
      def find(bucket, id, field=nil)
        fields = {'_id' => 0}
        fields[field] = 1 if field.present?

        result = collection(bucket).find_one({_id: id}, {fields: fields})
        result = field.split('.').inject(result){|acc, attr| acc = acc[attr]} if result.present? && field.present?

        result
      end
      
      def insert(bucket, document, field = nil)
        if (id = document.delete(:_id)).present?
          existing_document = find(bucket, id, field)
          document = existing_document.deep_merge(document) if existing_document.present?
          
          fields   = { field => document} if field.present?
          fields ||= document

          collection(bucket).update({:_id => id}, {'$set' => fields}, {upsert: true})
        else
          raise 'inserting!'
          collection(bucket).insert(document)
        end
      end
  end
end