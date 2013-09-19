require 'spec_helper'

describe Vayacondios::HttpClient, events: true, stashes: true do

  let(:organization) { 'organization' }
  let(:topic)        { 'topic'        }
  let(:id)           { 'id'           }

  let(:connection)   { mock("Net::HTTP") }
  
  let(:ok)           { double "Net::HTTPOK",                  code: '200', body: '{}'                       }
  let(:bad_request)  { double "Net::HTTPBadRequest",          code: '400', body: '{"error":"Your mistake"}' }
  let(:not_found)    { double "Net::HTTPNotFound",            code: '404', body: '{"error":"Not found"}'    }
  let(:server_error) { double "Net::HTTPInternalServerError", code: '500', body: '{"error":"Big Trouble"}'  }
  let(:empty)        { double "Net::HTTPInternalServerError", code: '500', body: 'worse trouble'            }

  let(:client) { Vayacondios::HttpClient.new(organization: organization) }
  before       { client.stub!(:connection).and_return(connection)        }
  subject      { client                                                  }

  describe "defaults to using" do
    it "localhost" do
      subject.host.should == 'localhost'
    end
    it "port 9000" do
      subject.port.should == 9000
    end
    it "timeout of 30 seconds" do
      subject.timeout.should == 30
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

    describe "set_many" do
      it "should send a PUT request to /v2/organization/stashes with the query and update" do
        connection.should_receive(:request) do |req|
          req.class.should == Net::HTTP::Put
          req.path.should  == '/v2/organization/stashes'
          req.body.should  == MultiJson.dump(query: stash_query, update: stash_update)
        end
        subject.set_many(stash_query, stash_update)
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

    describe "set_many!" do
      it "should send a POST request to /v2/organization/stashes with the query and replacement" do
        connection.should_receive(:request) do |req|
          req.class.should == Net::HTTP::Post
          req.path.should  == '/v2/organization/stashes'
          req.body.should  == MultiJson.dump(query: stash_query, update: stash_replacement)
        end
        subject.set_many!(stash_query, stash_replacement)
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

    describe "delete_many" do
      it "should send a DELETE request to /v2/organization/stashes with the query" do
        connection.should_receive(:request) do |req|
          req.class.should == Net::HTTP::Delete
          req.path.should  == '/v2/organization/stashes'
          req.body.should  == json_stash_query
        end
        subject.delete_many(stash_query)
      end
    end
  end

  describe "handling a" do
    before do
      client.log.stub!(:debug)
      client.log.stub!(:error)
    end
    context "200 OK" do
      subject { client.send(:handle_response, ok) }
      it                  { should == {}       }
      its(:response_code) { should == 200      }
      its(:success?)      { should be_true     }
      its(:error?)        { should be_false    }
      its(:not_found?)    { should be_false    }
      its(:bad?)          { should be_false    }
      its(:error_message) { should be_nil      }
      its(:body)          { should == ok.body  }
    end
    context "400 Bad Request" do
      subject { client.send(:handle_response, bad_request) }
      it                  { should == {'error' => 'Your mistake'} }
      its(:response_code) { should == 400                         }
      its(:success?)      { should be_false                       }
      its(:error?)        { should be_true                        }
      its(:not_found?)    { should be_false                       }
      its(:bad?)          { should be_true                        }
      its(:error_message) { should == 'Your mistake'              }
      its(:body)          { should == bad_request.body            }
    end
    context "404 Not Found" do
      subject { client.send(:handle_response, not_found) }
      it                  { should == {'error' => 'Not found'}    }
      its(:response_code) { should == 404                         }
      its(:success?)      { should be_false                       }
      its(:error?)        { should be_true                        }
      its(:not_found?)    { should be_true                        }
      its(:bad?)          { should be_false                       }
      its(:error_message) { should == 'Not found'                 }
      its(:body)          { should == not_found.body              }
    end
    context "500 Internal Server Error" do
      subject { client.send(:handle_response, server_error) }
      it                  { should == {'error' => 'Big Trouble'}  }
      its(:response_code) { should == 500                         }
      its(:success?)      { should be_false                       }
      its(:error?)        { should be_true                        }
      its(:not_found?)    { should be_false                       }
      its(:bad?)          { should be_true                        }
      its(:error_message) { should == 'Big Trouble'               }
      its(:body)          { should == server_error.body           }
    end
  end
  
end
