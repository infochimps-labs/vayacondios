require 'spec_helper'

describe Vayacondios::Server::Api, events: true do
  include Goliath::TestHelper
  include RequestHelper
  
  let(:timestamp) { Time.now }

  before { Timecop.freeze(timestamp) }
  after  { Timecop.return            }
  
  context "GET" do
    let(:verb) { 'GET' }

    context "/v2/organization/event/topic/id" do
      let(:path)  { '/v2/organization/event/topic/id' }
      it "returns a 404 when no event with the given ID can be found" do
        vcd(verb: verb, path: path, status: 404)
      end
      context "if the event is found" do
        before do
          mongo_query do |db|
            db.collection("organization.topic.events").insert({_id: 'id', t: timestamp, d: hash_event.merge(time: timestamp)})
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with the body of the event" do
          vcd(verb: verb, path: path, includes: hash_event)
        end
        it "and the original timestamp" do
          vcd(verb: verb, path: path, includes: {'time' => Time.at(timestamp.to_i).utc.to_s})
        end
        it "and the ID" do
          vcd(verb: verb, path: path, includes: { 'id' => 'id' })
        end
      end
    end

    context "/v2/organization/events/topic" do
      let(:path) { "/v2/organization/events/topic" }
      context "when no events match" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with a response body that is an empty array" do
          vcd(verb: verb, path: path, equals: [])
        end
      end
      context "when some events match" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.topic.events").insert({_id: "id-#{i}", t: (timestamp.utc - i), d: hash_event})
            end
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with a response body that includes each matching event " do
          vcd(verb: verb, path: path, includes: 3.times.map{ |i| {"id" => "id-#{i}", "time" => (timestamp - i).utc.iso8601(3) }.merge(hash_event) }.reverse)
        end
      end
    end
  end

  context "POST" do
    let(:verb) { "POST" }

    context "/v2/organization/event/topic" do
      let(:path) { "/v2/organization/event/topic" }
      context "with an empty event" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with a response that includes an ID and the time" do
          vcd(verb: verb, path: path, includes: %w[id time])
        end
        it "stores the event in the organization.topic.events collection with an auto-generated _id field" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            event = db.collection("organization.topic.events").find_one({}, sort: {t: -1})
            event.should_not be_nil
            event['_id'].should_not be_nil
            event['d'].should == {}
            event['t'].to_s.should == timestamp.utc.to_s
          end
        end
      end
      context "with a Hash event" do
        it "returns a 200" do
          vcd(verb: verb, path: path, body: hash_event, status: 200)
        end
        it "with the event" do
          vcd(verb: verb, path: path, body: hash_event, includes: hash_event)
        end
        it "and the auto-generated ID" do
          vcd(verb: verb, path: path, body: hash_event, includes: %w[id])
        end
        it "and the timestamp" do
          vcd(verb: verb, path: path, body: hash_event, includes: {'time' => timestamp.utc.to_s})
        end
        it "stores the event in the organization.topic.events collection with an auto-generated _id field" do
          vcd(verb: verb, path: path, body: hash_event)
          mongo_query do |db|
            event = db.collection("organization.topic.events").find_one({}, sort: {t: -1})
            event.should_not be_nil
            event['_id'].should_not be_nil
            event['d'].should == hash_event
            event['t'].to_s.should == timestamp.utc.to_s
          end
        end
      end
      context "with a non-Hash event" do
        it "returns a 400" do
          vcd(verb: verb, path: path, body: array_event, status: 400)
        end
        it "with an error message explaining that you need to use hashes" do
          vcd(verb: verb, path: path, body: array_event, error: /hash/i)
        end
        it "does not store any events in the organization.topic.events collection" do
          vcd(verb: verb, path: path, body: array_event)
          mongo_query do |db|
            db.collection("organization.topic.events").count.should == 0
          end
        end
      end
    end

    context "/v2/organization/event/topic/id" do
      let(:path) { "/v2/organization/event/topic/id" }
      context "with an empty event" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with the given ID" do
          vcd(verb: verb, path: path, includes: {"id" => 'id'})
        end
        it "and a timestamp" do
          vcd(verb: verb, path: path, includes: {'time' => timestamp.utc.to_s})
        end
        it "stores the event in the organization.topic.events collection with an auto-generated _id field" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            event = db.collection("organization.topic.events").find_one({}, sort: {t: -1})
            event.should_not be_nil
            event['_id'].should_not be_nil
            event['d'].should == {}
            event['t'].to_s.should == timestamp.utc.to_s
          end
        end
      end
      context "with a Hash event" do
        it "returns a 200" do
          vcd(verb: verb, path: path, body: hash_event, status: 200)
        end
        it "with the event" do
          vcd(verb: verb, path: path, body: hash_event, includes: hash_event)
        end
        it "and the ID" do
          vcd(verb: verb, path: path, body: hash_event, includes: {'id' => 'id'})
        end
        it "and a timestamp" do
          vcd(verb: verb, path: path, body: hash_event, includes: { 'time' => timestamp.utc.to_s })
        end
        it "stores the event in the organization.topic.events collection with an _id field given by the ID" do
          vcd(verb: verb, path: path, body: hash_event)
          mongo_query do |db|
            event = db.collection("organization.topic.events").find_one({_id: 'id'}, sort: {t: -1})
            event.should_not be_nil
            event['_id'].should == 'id'
            event['d'].should == hash_event
            event['t'].to_s.should == timestamp.utc.to_s
          end
        end
      end
      context "with a non-Hash event" do
        it "returns a 400" do
          vcd(verb: verb, path: path, body: array_event, status: 400)
        end
        it "with an error message explaining that you need to use hashes" do
          vcd(verb: verb, path: path, body: array_event, error: /hash/i)
        end
        it "does not store any events in the organization.topic.events collection" do
          vcd(verb: verb, path: path, body: array_event)
          mongo_query do |db|
            db.collection("organization.topic.events").count.should == 0
          end
        end
      end
    end
  end

  context "PUT" do
    let(:verb) { 'PUT' }
    context "/v2/organization/event/topic" do
      let(:path) { "/v2/organization/event/topic" }
      it "returns a 404" do
        vcd(verb: verb, path: path, status: 404)
      end
      it "with an error message explaining the route doesn't exist" do
        vcd(verb: verb, path: path, error: /PUT/)
      end
    end
    context "/v2/organization/event/topic/id" do
      let(:path) { "/v2/organization/event/topic/id" }
      it "returns a 404" do
        vcd(verb: verb, path: path, status: 404)
      end
      it "with an error message explaining the route doesn't exist" do
        vcd(verb: verb, path: path, error: /PUT/)
      end
    end
  end

  context "DELETE" do
    let(:verb) { 'DELETE' }
    context "/v2/organization/event/topic" do
      let(:path) { "/v2/organization/event/topic" }
      it "returns a 404" do
        vcd(verb: verb, path: path, status: 404)
      end
      it "with an error message explaining the route doesn't exist" do
        vcd(verb: verb, path: path, error: /DELETE/)
      end
    end
    context "/v2/organization/event/topic/id" do
      let(:path) { "/v2/organization/event/topic/id" }
      it "returns a 404" do
        vcd(verb: verb, path: path, status: 404)
      end
      it "with an error message explaining the route doesn't exist" do
        vcd(verb: verb, path: path, error: /DELETE/)
      end
    end
  end
end
