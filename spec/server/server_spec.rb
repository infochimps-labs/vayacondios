require 'spec_helper'

require 'multi_json'

require File.join(File.dirname(__FILE__), '../../', 'app/http_shim')

describe HttpShim do
  include Goliath::TestHelper

  def config_file
    File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', 'app.rb'))
  end

  def mock_mongo(api)
    api.config['mongo'] = mock('mongo').as_null_object
  end

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }
  let(:api_options) { { :config => config_file } }

  it "responds to requests" do
    with_api(HttpShim, api_options) do |api|
      mock_mongo(api)

      get_request({}, err) do |c|
        c.response_header.status.should == 400
        c.response.should eql MultiJson.dump({:error => "Bad Request"})
      end
    end
  end
end