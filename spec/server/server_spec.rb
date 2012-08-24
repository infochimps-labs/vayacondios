require 'spec_helper'

require 'multi_json'

require File.join(File.dirname(__FILE__), '../../', 'app/http_shim')

describe HttpShim do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }

  it "responds to requests" do
    with_api(HttpShim) do |api|
      get_request({}, err) do |c|
        c.response_header.status.should == 400
        MultiJson.load(c.response).should eql({"error" => "Bad Request"})
      end
    end
  end
end