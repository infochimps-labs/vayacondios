require 'spec_helper'

require 'multi_json'

require File.join(File.dirname(__FILE__), '../../', 'app/http_shim')

describe HttpShim do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }

  context 'Event tracking' do
    it 'requires a topic' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/event/',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 400
        end
      end
    end
    
    it 'does not require an id' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/event/power',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 200
        end
      end
    end

    it 'will accept an id' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/event/power/level',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 200
        end
      end
    end

    it 'rejects deep IDs' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/event/power/level/is/invalid',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 400
        end
        
        get_mongo_db do |db|
          db.collection("infochimps.config").find_one({:_id => "power"}).should be_nil
        end
      end
    end

    it 'stores events' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/event/power/level',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql ({"level" => "awesome"})
        end
        
        get_mongo_db do |db|
          doc = db.collection("infochimps.power.events").find_one({:_id => "level"})
          doc["_id"].should eql "level"
          doc["d"].should eql ({"level" => "awesome"})
          doc["t"].should be_within(1).of Time.now
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