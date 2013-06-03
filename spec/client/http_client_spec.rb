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
          it "should send a POST request to /v1/organization/event/topic with the Hash as the body" do
            connection.should_receive(:post).with("/v1/organization/event/topic", json_hash_event, subject.headers)
            subject.announce(topic, hash_event)
          end
        end
        context "with an Array event" do
          it "should send a POST request to /v1/organization/event/topic with the Array as the body" do
            connection.should_receive(:post).with("/v1/organization/event/topic", json_array_event, subject.headers)
            subject.announce(topic, array_event)
          end
        end
        context "with a String event" do
          it "should send a POST request to /v1/organization/event/topic with the String as the body" do
            connection.should_receive(:post).with("/v1/organization/event/topic", json_string_event, subject.headers)
            subject.announce(topic, string_event)
          end
        end
      end
      context "with an ID" do
        context "with a Hash event" do
          it "should send a POST request to /v1/organization/event/topic/id with the Hash as the body" do
            connection.should_receive(:post).with("/v1/organization/event/topic/id", json_hash_event, subject.headers)
            subject.announce(topic, hash_event, id)
          end
        end
        context "with an Array event" do
          it "should send a POST request to /v1/organization/event/topic/id with the Array as the body" do
            connection.should_receive(:post).with("/v1/organization/event/topic/id", json_array_event, subject.headers)
            subject.announce(topic, array_event, id)
          end
        end
        context "with a String event" do
          it "should send a POST request to /v1/organization/event/topic/id with the String as the body" do
            connection.should_receive(:post).with("/v1/organization/event/topic/id", json_string_event, subject.headers)
            subject.announce(topic, string_event, id)
          end
        end
      end
    end

    describe "#get" do
      context "without an ID" do
        it "should send a GET request to /v1/organizations/stash/topic" do
          connection.should_receive(:get).with("/v1/organization/stash/topic")
          subject.get(topic)
        end
      end
      context "with an ID" do
        it "should send a GET request to /v1/organizations/stash/topic/id" do
          connection.should_receive(:get).with("/v1/organization/stash/topic/id")
          subject.get(topic, id)
        end
      end
    end

    describe "#set" do
      context "without an ID" do
        context "with a Hash stash" do
          it "should send a PUT request to /v1/organization/stash/topic with the Hash as the body" do
            connection.should_receive(:put).with("/v1/organization/stash/topic", json_hash_stash, subject.headers)
            subject.set(topic, nil, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a PUT request to /v1/organization/stash/topic with the Array as the body" do
            connection.should_receive(:put).with("/v1/organization/stash/topic", json_array_stash, subject.headers)
            subject.set(topic, nil, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a PUT request to /v1/organization/stash/topic with the String as the body" do
            connection.should_receive(:put).with("/v1/organization/stash/topic", json_string_stash, subject.headers)
            subject.set(topic, nil, string_stash)
          end
        end
      end
      
      context "with an ID" do
        context "with a Hash stash" do
          it "should send a PUT request to /v1/organization/stash/topic/id with the Hash as the body" do
            connection.should_receive(:put).with("/v1/organization/stash/topic/id", json_hash_stash, subject.headers)
            subject.set(topic, id, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a PUT request to /v1/organization/stash/topic/id with the Array as the body" do
            connection.should_receive(:put).with("/v1/organization/stash/topic/id", json_array_stash, subject.headers)
            subject.set(topic, id, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a PUT request to /v1/organization/stash/topic/id with the String as the body" do
            connection.should_receive(:put).with("/v1/organization/stash/topic/id", json_string_stash, subject.headers)
            subject.set(topic, id, string_stash)
          end
        end
      end
    end

    describe "#set!" do
      context "without an ID" do
        context "with a Hash stash" do
          it "should send a POST request to /v1/organization/stash/topic with the Hash as the body" do
            connection.should_receive(:post).with("/v1/organization/stash/topic", json_hash_stash, subject.headers)
            subject.set!(topic, nil, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a POST request to /v1/organization/stash/topic with the Array as the body" do
            connection.should_receive(:post).with("/v1/organization/stash/topic", json_array_stash, subject.headers)
            subject.set!(topic, nil, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a POST request to /v1/organization/stash/topic with the String as the body" do
            connection.should_receive(:post).with("/v1/organization/stash/topic", json_string_stash, subject.headers)
            subject.set!(topic, nil, string_stash)
          end
        end
      end
      
      context "with an ID" do
        context "with a Hash stash" do
          it "should send a POST request to /v1/organization/stash/topic/id with the Hash as the body" do
            connection.should_receive(:post).with("/v1/organization/stash/topic/id", json_hash_stash, subject.headers)
            subject.set!(topic, id, hash_stash)
          end
        end
        context "with an Array stash" do
          it "should send a POST request to /v1/organization/stash/topic/id with the Array as the body" do
            connection.should_receive(:post).with("/v1/organization/stash/topic/id", json_array_stash, subject.headers)
            subject.set!(topic, id, array_stash)
          end
        end
        context "with a String stash" do
          it "should send a POST request to /v1/organization/stash/topic/id with the String as the body" do
            connection.should_receive(:post).with("/v1/organization/stash/topic/id", json_string_stash, subject.headers)
            subject.set!(topic, id, string_stash)
          end
        end
      end
    end

    describe "#delete" do
      context "without an ID" do
        it "should send a DELETE request to /v1/organizations/stash/topic" do
          connection.should_receive(:delete).with("/v1/organization/stash/topic")
          subject.delete(topic)
        end
      end
      context "with an ID" do
        it "should send a DELETE request to /v1/organizations/stash/topic/id" do
          connection.should_receive(:delete).with("/v1/organization/stash/topic/id")
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
