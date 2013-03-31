require 'spec_helper'

require 'multi_json'

require 'vayacondios/server/api'

describe Vayacondios::Server do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }

  it "responds to requests" do
    with_api(Vayacondios::Server) do |api|
      get_request({}, err) do |c|
        c.response_header.status.should == 400
        MultiJson.load(c.response).should eql({"error" => "Bad Request. Format path is <host>/v1/<org>/event/<topic>"})
      end
    end
  end
end
