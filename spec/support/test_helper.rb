module Goliath
  module TestHelper
    DEFAULT_ERRBACK = Proc.new{|c| fail "HTTP Request failed #{c.response}" }

    def config_file
      Goliath.root_dir(BASE_DIR, 'config', 'app.rb')
    end

    def get_api_request query={}, params={}, errback=DEFAULT_ERRBACK, &block
      query.reverse_merge!( :_apikey => DEFAULT_APIKEY )
      params[:query] = query
      get_request(params, errback, &block)
    end

    def db
      @db ||= DirectMongoDb.new(@api_server.config['broham'])
    end

    def should_have_ok_response(c)
      [c.response, c.response_header.status].should == ['Hello from Responder', 200]
    end
  end
end
