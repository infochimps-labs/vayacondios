require 'spec_helper'

describe Vayacondios::HttpClient, events: true, stashes: true do

  let(:organization) { 'organization' }
  let(:topic)        { 'topic'        }
  let(:id)           { 'id'           }

  let(:connection)   { mock("Net::HTTP") }
  
  let(:ok)           { double "Net::HTTPOK",                  code: '200', body: '{}'                       }
  let(:bad_request)  { double "Net::HTTPBadRequest",          code: '400', body: '{"error":"Your mistake"}' }
  let(:not_found)    { double "Net::HTTPNotFound",            code: '404', body: '{}'                       }
  let(:server_error) { double "Net::HTTPInternalServerError", code: '500', body: '{"error":"Big Trouble"}'  }
  let(:empty)        { double "Net::HTTPInternalServerError", code: '500', body: 'worse trouble'            }

  subject { Vayacondios::HttpClient.new(organization: organization) }
  before  { subject.stub!(:connection).and_return(connection)       }

  describe "defaults to using" do
    it "localhost" do
      subject.host.should == 'localhost'
    end
    it "port 9000" do
      subject.port.should == 9000
    end
  end

  describe "making requests" do
    before { subject.stub!(:handle_response) }
    
    describe "#announce" do
      context "without an ID" do
        context "with a Hash event" do
          it "should send a POST request to /v2/organization/event/topic with the Hash as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/event/topic"
              req.body.should  == json_hash_event
            end
            subject.announce(topic, hash_event)
          end
        end
        context "with an Array event" do
          it "should send a POST request to /v2/organization/event/topic with the Array as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/event/topic"
              req.body.should  == json_array_event
            end
            subject.announce(topic, array_event)
          end
        end
        context "with a String event" do
          it "should send a POST request to /v2/organization/event/topic with the String as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/event/topic"
              req.body.should  == json_string_event
            end
            subject.announce(topic, string_event)
          end
        end
      end
      context "with an ID" do
        context "with a Hash event" do
          it "should send a POST request to /v2/organization/event/topic/id with the Hash as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/event/topic/id"
              req.body.should  == json_hash_event
            end
            subject.announce(topic, hash_event, id)
          end
        end
        context "with an Array event" do
          it "should send a POST request to /v2/organization/event/topic/id with the Array as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/event/topic/id"
              req.body.should  == json_array_event
            end
            subject.announce(topic, array_event, id)
          end
        end
        context "with a String event" do
          it "should send a POST request to /v2/organization/event/topic/id with the String as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/event/topic/id"
              req.body.should  == json_string_event
            end
            subject.announce(topic, string_event, id)
          end
        end
      end
    end

    describe "#events" do
      context "without a query" do
        it "sends a GET request to /v2/organization/events/topic" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Get
            req.path.should  == "/v2/organization/events/topic"
            req.body.should  == nil
          end
          subject.events(topic)
        end
      end
      context "with a query" do
        it "sends a GET request to /v2/organization/events/topic with the query as a body" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Get
            req.path.should  == "/v2/organization/events/topic"
            req.body.should  == json_event_query
          end
          subject.events(topic, event_query)
        end
      end
    end
    
    describe "#get" do
      context "without an ID" do
        it "should send a GET request to /v2/organization/stash/topic" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Get
            req.path.should  == "/v2/organization/stash/topic"
            req.body.should  == nil
          end
          subject.get(topic)
        end
      end
      context "with an ID" do
        it "should send a GET request to /v2/organization/stash/topic/id" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Get
            req.path.should  == "/v2/organization/stash/topic/id"
            req.body.should  == nil
          end
          subject.get(topic, id)
        end
      end
    end

    describe "#stashes" do
      context "without a query" do
        it "sends a GET request to /v2/organization/stashes" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Get
            req.path.should  == "/v2/organization/stashes"
            req.body.should  == '{}'
          end
          subject.stashes()
        end
      end
      context "with a query" do
        it "sends a GET request to /v2/organization/stashes with the query as a body" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Get
            req.path.should  == "/v2/organization/stashes"
            req.body.should == json_stash_query
          end
          subject.stashes(stash_query)
        end
      end
    end
    
    describe "#set" do
      context "without an ID" do
        context "with a Hash stash" do
          it "should send a PUT request to /v2/organization/stash/topic with the Hash as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Put
              req.path.should  == "/v2/organization/stash/topic"
              req.body.should  == json_hash_stash
            end
            subject.set(topic, nil, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a PUT request to /v2/organization/stash/topic with the Array as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Put
              req.path.should  == "/v2/organization/stash/topic"
              req.body.should  == json_array_stash
            end
            subject.set(topic, nil, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a PUT request to /v2/organization/stash/topic with the String as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Put
              req.path.should  == "/v2/organization/stash/topic"
              req.body.should  == json_string_stash
            end
            subject.set(topic, nil, string_stash)
          end
        end
      end
      
      context "with an ID" do
        context "with a Hash stash" do
          it "should send a PUT request to /v2/organization/stash/topic/id with the Hash as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Put
              req.path.should  == "/v2/organization/stash/topic/id"
              req.body.should  == json_hash_stash
            end
            subject.set(topic, id, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a PUT request to /v2/organization/stash/topic/id with the Array as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Put
              req.path.should  == "/v2/organization/stash/topic/id"
              req.body.should  == json_array_stash
            end
            subject.set(topic, id, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a PUT request to /v2/organization/stash/topic/id with the String as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Put
              req.path.should  == "/v2/organization/stash/topic/id"
              req.body.should  == json_string_stash
            end
            subject.set(topic, id, string_stash)
          end
        end
      end
    end

    describe "#set!" do
      context "without an ID" do
        context "with a Hash stash" do
          it "should send a POST request to /v2/organization/stash/topic with the Hash as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/stash/topic"
              req.body.should  == json_hash_stash
            end
            subject.set!(topic, nil, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a POST request to /v2/organization/stash/topic with the Array as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/stash/topic"
              req.body.should == json_array_stash
            end
            subject.set!(topic, nil, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a POST request to /v2/organization/stash/topic with the String as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/stash/topic"
              req.body.should  == json_string_stash
            end
            subject.set!(topic, nil, string_stash)
          end
        end
      end
      
      context "with an ID" do
        context "with a Hash stash" do
          it "should send a POST request to /v2/organization/stash/topic/id with the Hash as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/stash/topic/id"
              req.body.should  == json_hash_stash
            end
            subject.set!(topic, id, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a POST request to /v2/organization/stash/topic/id with the Array as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/stash/topic/id"
              req.body.should  == json_array_stash
            end
            subject.set!(topic, id, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a POST request to /v2/organization/stash/topic/id with the String as the body" do
            connection.should_receive(:request) do |req|
              req.class.should == Net::HTTP::Post
              req.path.should  == "/v2/organization/stash/topic/id"
              req.body.should  == json_string_stash
            end
            subject.set!(topic, id, string_stash)
          end
        end
      end
    end

    describe "#delete" do
      context "without an ID" do
        it "should send a DELETE request to /v2/organization/stash/topic" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Delete
            req.path.should  == "/v2/organization/stash/topic"
            req.body.should  == nil
          end
          subject.delete(topic)
        end
      end
      context "with an ID" do
        it "should send a DELETE request to /v2/organization/stash/topic/id" do
          connection.should_receive(:request) do |req|
            req.class.should == Net::HTTP::Delete
            req.path.should  == "/v2/organization/stash/topic/id"
            req.body.should  == nil
          end
          subject.delete(topic, id)
        end
      end
    end
  end

  describe "handling a" do
    before do
      subject.log.stub!(:debug)
      subject.log.stub!(:error)
    end
    context "200 OK" do
      it "returns the parsed content of the response body" do
        subject.send(:handle_response, ok).should == {}
      end
    end
    context "400 Bad Request" do
      it "returns nil" do
        subject.send(:handle_response, bad_request).should be_nil
      end
    end
    context "404 Not Found" do
      it "returns nil" do
        subject.send(:handle_response, not_found).should be_nil
      end
    end
    context "500 Internal Server Error" do
      it "returns nil" do
        subject.send(:handle_response, server_error).should be_nil
      end
    end
  end
  
end
