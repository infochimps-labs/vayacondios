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

        result = insert(bucket, params.merge({_id: id}), field)

        [200, {}, { :result => { :bucket => bucket, :id => id||result.to_s }}]
      end

      def get(path)        
        bucket, id, field = parse_path(path)
        
        fields = {'_id' => 0}
        fields[field] = 1 if field.present?

        result = collection(bucket).find_one({_id: id}, {fields: fields})

        if result.present?
          result = field.split('.').inject(result){|acc, attr| acc = acc[attr]} if field.present?
          [200, {}, result]
        else
          [404, {}, {error: 'Not Found'}]
        end
      end
      
      def parse_path(path)
        bucket   = [path[:organization], path[:type]].join('.')
        segments = path[:id].to_s.split('/').reject(&:blank?)

        id       = segments.shift
        field    = segments.join('.')
        id       = BSON::ObjectId(id) if id.to_s.match(/^[a-f0-9]{24}$/)
        
        [bucket, id, field]
      end
      
      def collection(bucket)
        collection = DB.collection(bucket)
      end
      
      def insert(bucket, document, field = nil)
        if document[:_id].present?
          fields   = { field => document} if field.present?
          fields ||= document

          collection(bucket).update({:_id => fields.delete(:_id)}, {'$set' => fields}, {upsert: true})
        else
          collection(bucket).insert(document)
        end
      end
  end
end