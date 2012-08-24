require 'spec_helper'

require 'multi_json'

require File.join(File.dirname(__FILE__), '../../', 'app/http_shim')

describe HttpShim do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }

  context 'Event tracking' do
    it 'stores events' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/event/power/level',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql ({"level" => "awesome"})
        end
      end
    end

    it 'retrieves events' do
      current_time = Time.now
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/event/power/level',
          :body => {:level=>"awesome", :_timestamp => current_time}
        }, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql ({"level" => "awesome", "_timestamp" => current_time.to_s})
        end
      end
      with_api(HttpShim) do |api|
        get_request({:path => '/v1/infochimps/event/power/level'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql ({"level" => "awesome", "_timestamp" => current_time.to_s})
        end
      end
    end
  end
end