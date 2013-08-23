require 'spec_helper'

require 'multi_json'
require 'vayacondios-server'

describe Vayacondios::HttpServer do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }

  context 'Basic requirements' do
    it 'requires a topic' do
      #Vayacondios.force_legacy_mode(true)
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/',
          :body => MultiJson.dump(["foo"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
      end
    end

    it 'requires an id' do
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power',
          :body => MultiJson.dump(["foo"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end

        mongo_query do |db|
          db.collection("infochimps.power.itemset").find_one().should be_nil
        end
      end
    end

    it 'rejects deep IDs' do
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level/is/invalid',
          :body => MultiJson.dump(["foo"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end

        mongo_query do |db|
          db.collection("infochimps.power.itemset").find_one({:_id => "level"}).should be_nil
        end
      end
    end
  end


  context 'can handle GET requests' do
      #Vayacondios.force_legacy_mode(true)

    it 'and return 404 for missing resources' do
      with_api(Vayacondios::HttpServer) do |api|
      #Vayacondios.force_legacy_mode(true)

        get_request({:path => '/v1/infochimps/itemset/missing/resource'}, err) do |c|
          c.response_header.status.should == 404
        end
      end
    end

    it 'and return an array for valid resources' do

      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(["foo", "bar"]),
          :head => { :content_type => 'application/json' }
        }, err)
      end
      with_api(Vayacondios::HttpServer) do |api|
        get_request({:path => '/v1/infochimps/itemset/power/level'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql(["foo", "bar"])
        end
      end
    end
  end

  context "will not handle POST requests" do
    it 'fails on POST' do
      with_api(Vayacondios::HttpServer) do |api|
        post_request({
          :path => '/v1/infochimps/itemset/post/unsupported',
          :body => MultiJson.dump({ :totally => :ignored }),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should eql 405

          # I'm removing this piece of the legacy functionality for
          # now, since our old customers should know better than to
          # POST; and, in any event, the reason behind the message
          # returned when they do so should be fairly obvious.
          # c.response_header["ALLOW"].should_not be_nil
        end
      end
    end
  end

  context "handles PATCH requests in legacy mode" do
    it 'merges with PATCH' do
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/merge/test',
          :body => MultiJson.dump(["foo"]),
          :head => { :content_type => 'application/json' }
        }, err)
      end
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/merge/test',
          :head => ({'X-Method' => 'PATCH', :content_type => 'application/json' }),
          :body => MultiJson.dump(["bar"])
        }, err)
      end
      with_api(Vayacondios::HttpServer) do |api|
        get_request({:path => '/v1/infochimps/itemset/merge/test'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql(["foo", "bar"])
        end
      end
    end
  end

  context "will handle DELETE requests in legacy mode" do
    it "will be ok to delete items that don't exist" do
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(["foo"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 201 Created
        end
      end
      with_api(Vayacondios::HttpServer) do |api|
        delete_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(["bar"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 204 No content
        end
      end
    end

    it "will delete items that do exist" do
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(["foo", "bar"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Makes this 201 Created
        end
      end
      with_api(Vayacondios::HttpServer) do |api|
        delete_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(["bar"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 204 No content
        end
      end
      with_api(Vayacondios::HttpServer) do |api|
        get_request({:path => '/v1/infochimps/itemset/power/level'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql(["foo"])
        end
      end
    end

    it "leaves behind an empty array if everything is deleted" do
      with_api(Vayacondios::HttpServer) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(["foo", "bar"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Makes this 201 Created
        end
      end
      with_api(Vayacondios::HttpServer) do |api|
        delete_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(["foo", "bar"]),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 204 No content
        end
      end
      with_api(Vayacondios::HttpServer) do |api|
        get_request({:path => '/v1/infochimps/itemset/power/level'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql([])
        end
      end
    end
  end
end
