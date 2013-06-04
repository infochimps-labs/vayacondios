require 'spec_helper'

describe Vayacondios::HttpServer, events: true do
  include Goliath::TestHelper

  let(:timestamp) { Time.now }

  context "GET" do
    let(:verb) { 'GET' }

    context "/v1/organization/event/topic/id" do
      let(:path)  { '/v1/organization/event/topic/id' }
      context "if the event isn't found" do
        it "returns a 404" do
          vcd_test(verb: 'GET', path: '/v1/organization/event/topic/id', status: 404)
        end
      end
      context "if the event is found" do
        before do
          mongo_query do |db|
            db.collection("organization.topic.events").insert({_id: 'id', t: timestamp, d: hash_event.merge(time: timestamp)})
          end
        end
        it "returns a 200" do
          vcd_test(verb: verb, path: path, status: 200)
        end
        it "returns the body of the event with the original timestamp converted to a UTC string" do
          vcd_test(verb: verb, path: path, response: hash_event.merge('time' => Time.at(timestamp.to_i).utc.to_s))
        end
      end
    end
  end

  context "POST" do
    let(:verb) { "POST" }

    context "/v1/organization/event/topic" do
      let(:path) { "/v1/organization/event/topic" }
      context "without a body" do
        it "returns a 200" do
          vcd_test(verb: verb, path: path, status: 200)
        end
        it "with an empty Hash response" do
          vcd_test(verb: verb, path: path, response: {})
        end
      end
      context "with a Hash" do
        it "returns a 200" do
          vcd_test(verb: verb, path: path, status: 200)
        end
        it "with the event as a response" do
          vcd_test(verb: verb, path: path, response: hash_event)
        end
        it "stores the event in the organization.topic.events collection with an auto-generated ID" do
          mongo_query do |db|
            event = db.collection("organization.topic.events").find_one({}, sort: {t: -1})
            event.should_not be_nil
            event['_id'].should_not be_nil
            event['d'].should == hash_event
            event['t'].should be_within(1).of(Time.now)
          end
        end
      end
      context "with a non-Hash" do
        it "returns a 400" do
          vcd_test(verb: verb, path: path, status: 400)
        end
        it "with an error message explaining that you need to use hashes" do
          vcd_test(verb: verb, path: path, error: /hash/)
        end
      end
    end
  end

  context "PUT" do
    context "/v1/organization/event/topic" do
      it "returns a 400" do
        vcd_test(verb: 'PUT', path: '/v1/organization/event/topic', status: 400)
      end
      it "with an error message explaining that you can't update events" do
        vcd_test(verb: 'PUT', path: '/v1/organization/event/topic', error: /update/)
      end
    end
  end
  
end

  

      

    
  #   it 'does not require an id' do
  #     with_api(Vayacondios::HttpServer) do |api|
  #       put_request({
  #         :path => '/v1/infochimps/event/power',
  #         :body => MultiJson.dump({:level=>"awesome"}),
  #         :head => { :content_type => 'application/json' }
  #       }, err) do |c|
  #         c.response_header.status.should == 200
  #       end
  #     end
  #   end

  #   it 'will accept an id' do
  #     with_api(Vayacondios::HttpServer) do |api|
  #       put_request({
  #         :path => '/v1/infochimps/event/power/level',
  #         :body => MultiJson.dump({:level=>"awesome"}),
  #         :head => { :content_type => 'application/json' }
  #       }, err) do |c|
  #         c.response_header.status.should == 200
  #       end
  #     end
  #   end

  #   it 'rejects deep IDs' do
  #     with_api(Vayacondios::HttpServer) do |api|
  #       put_request({
  #         :path => '/v1/infochimps/event/power/level/is/invalid',
  #         :body => MultiJson.dump({:level=>"awesome"}),
  #         :head => { :content_type => 'application/json' }
  #       }, err) do |c|
  #         c.response_header.status.should == 400
  #       end
        
  #       get_mongo_db do |db|
  #         db.collection("infochimps.config").find_one({:_id => "power"}).should be_nil
  #       end
  #     end
  #   end

  #   it 'stores events' do
  #     with_api(Vayacondios::HttpServer) do |api|
  #       put_request({
  #         :path => '/v1/infochimps/event/power/level',
  #         :body => MultiJson.dump({:level=>"awesome"}),
  #         :head => { :content_type => 'application/json' }
  #       }, err) do |c|
  #         c.response_header.status.should == 200
  #       end
        
  #       get_mongo_db do |db|
  #         doc = db.collection("infochimps.power.events").find_one({:_id => "level"})
  #         doc["_id"].should eql "level"
  #         doc["d"].should eql ({"level" => "awesome"})
  #         doc["t"].should be_within(1).of Time.now
  #       end
  #     end
  #   end

  #   it 'retrieves events' do
  #     current_time = Time.now
  #     with_api(Vayacondios::HttpServer) do |api|
  #       put_request({
  #         :path => '/v1/infochimps/event/power/level',
  #         :body => MultiJson.dump({:level=>"awesome", :_timestamp => current_time}),
  #         :head => { :content_type => 'application/json' }
  #       }, err) do |c|
  #         c.response_header.status.should == 200
  #       end
  #     end
  #     with_api(Vayacondios::HttpServer) do |api|
  #       get_request({:path => '/v1/infochimps/event/power/level'}, err) do |c|
  #         c.response_header.status.should == 200
  #         MultiJson.load(c.response).should eql ({"level" => "awesome", "_timestamp" => current_time.to_s})
  #       end
  #     end
  #   end
  # end
