class HttpShim < Goliath::API
  class Version0 < Goliath::API
    def response(env, path_params={})      
      if %{PUT POST}.include?(env['REQUEST_METHOD'])
        bucket = path_params[:bucket].sub(/^\//, '').gsub(/[\W_]+/, '_')
        post(bucket, env.params)
      elsif env['REQUEST_METHOD'] == 'GET'
        segments = path_params[:bucket].split('/')
        bucket   = segments[0...-1].join('/').sub(/^\//, '').gsub(/[\W_]+/, '_')
        id       = segments.last

        get(bucket, id)
      else
        [400, {}, {}]
      end
    end

  protected

      def post(bucket, params)
        raise ArgumentError, "Must specify a bucket name in the path" unless bucket.present?
        
        document = {d: params}
        document[:_id] = document[:d].delete("_id") if document[:d].has_key? "_id"

        begin
          document[:t]   = Time.parse(document[:d].delete("_ts")) if document[:d].has_key?("_ts")
        rescue
          raise ArgumentError, "_ts field contained invalid time string"
        end
        document[:t] ||= Time.now

        result = insert(bucket, document, upsert)

        [200, {}, { :result => { :bucket => bucket, :id => result.to_s }}]
      end

      def get(bucket, id)
        begin 
          id = BSON::ObjectId(id)
        rescue
          return [404, {}, {error: 'Not Found'}]
        end
        result = collection(bucket).find_one({_id: id})

        if result.present?
          [200, {}, result]
        else
          [404, {}, {error: 'Not Found'}]
        end
      end
      
      def collection(bucket)
        collection = DB.collection(bucket + '_events')
      end
      
      def insert(bucket, document)     
        if document[:_id]
          collection(bucket).update({:_id => document[:_id]}, document, {:upsert => true})
        else
          collection(bucket).insert(document)
        end
      end
  end
end