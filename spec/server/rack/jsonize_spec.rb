require 'spec_helper'

describe Vayacondios::Rack::JSONize, rack: true do

  subject { described_class.new(upstream)   }

  describe "processing requests" do
    it "sets the Content-Type to 'application/json' on all requests it upstream" do
      upstream.should_receive(:call)
        .with(env.merge({
          'CONTENT_TYPE'   => 'application/json',
          'async.callback' => kind_of(Proc)
        }))
        .and_return([200, {'CONTENT_TYPE' => 'application/json'}, ['']])
      subject.call(env)
    end
  end

  describe "processing responses" do
    context "from the upstream /status path" do
      
      let(:response) { described_class.new(upstream).post_process(env.merge("REQUEST_PATH" => "/status"), upstream_status, upstream_headers, upstream_body) }

      describe "the downstream status" do
        subject { response[0]               }
        it      { should == upstream_status }
      end
      
      describe "the downstream headers" do
        subject { response[1]                }
        it      { should == upstream_headers }
      end

      describe "the downstream body" do
        subject { response[2]             }
        it      { should == upstream_body }
      end
    end
    
    context "everywhere else" do

      let(:response) { described_class.new(upstream).post_process(env, upstream_status, upstream_headers, upstream_body) }

      describe "the downstream status" do
        subject { response[0]               }
        it      { should == upstream_status }
      end
      
      describe "the downstream headers" do
        subject { response[1]       }
        it      { should include("Content-Type" => "application/json") }
      end

      describe "the downstream body" do
        subject { response[2]         }
        it      { should == [MultiJson.dump(upstream_body) + "\n"] }
      end
    end
  end
  
end
