require 'spec_helper'

describe Vayacondios::HttpServer do
  include Goliath::TestHelper

  context "/status" do
    it "returns a 200" do
      vcd_test verb: 'GET', path: '/status', status: 200
    end
    it "with OK" do
      vcd_test verb: 'GET', path: '/status' do
        response.should == 'OK'
      end
    end
  end

  context "a path which doesn't match the  /v1/organization/stash|event/topic[/id] structure" do
    it "returns a 400" do
      vcd_test verb: 'GET', path: '/gobbledygook', status: 400
    end
  end
  
end
