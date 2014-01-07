require 'spec_helper'

describe Vayacondios::HttpServer do

  include Goliath::TestHelper
  include RequestHelper

  # let(:vayacondios) { nil }

  # before(:all) do
  #   vayacondios = server(Vayacondios::HttpServer, 9900, config: File.join(VCD_ROOT, 'config/vcd-server.rb'), environment: 'test')
  # end

  # after(:all) do
  #   EM.stop
  # end
  

  context "/status" do
    it "returns a 200" do
      vcd verb: 'GET', path: '/status', status: 200
      #   req = EM::HttpRequest.new("http://localhost:9900/status", {}).get({})
      #   req.callback do
      #     response_header.should == 200
      #   end
      #   req.errback do
      #     puts "ERROR"
      #   end
      # end
    end
    #   it "with OK" do
    #     vcd verb: 'GET', path: '/status', matches: 'OK'
    #   end
    # end

    # context "a path which doesn't match the API structure" do
    #   it "returns a 400" do
    #     vcd verb: 'GET', path: '/gobbledygook', status: 400
    #   end
    # end
    
  end
end
