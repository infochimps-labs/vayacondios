require 'spec_helper'

require 'multi_json'

require 'vayacondios/server/api'

describe Vayacondios::Server do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }

  context 'Basic requirements' do
    it 'requires a topic' do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/',
          :body => MultiJson.dump({:contents =>["foo"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
      end
    end
    
    it 'requires an id' do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power',
          :body => MultiJson.dump({:contents =>["foo"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
  
        get_mongo_db do |db|
          db.collection("infochimps.power.itemset").find_one().should be_nil
        end
      end
    end
    
    it 'rejects deep IDs' do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level/is/invalid',
          :body => MultiJson.dump({:contents =>["foo"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
        
        get_mongo_db do |db|
          db.collection("infochimps.power.itemset").find_one({:_id => "level"}).should be_nil
        end
      end
    end
  end
    
  context 'handles PUT requests' do
    it 'only accepts hashes' do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump(['foo', 'bar']),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 500
        end
        
        get_mongo_db do |db|
          db.collection("infochimps.itemset").find_one({:_id => "power"}).should be_nil
        end
      end
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => "foo",
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
        
        get_mongo_db do |db|
          db.collection("infochimps.itemset").find_one({:_id => "power"}).should be_nil
        end
      end
    end
    
    it "stores the array when the resource doesn't exist" do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["foo", "bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 201 Created
          c.response.should eql ""
        end
        
        get_mongo_db do |db|
          db.collection("infochimps.power.itemset").find_one({:_id => "level"})["d"].should eql ["foo", "bar"]
        end
      end
    end
    
    it "clobbers the previous array when the resource does exist" do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["chimpanzee", "bonobo"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 204 No content
          c.response.should eql ""
        end
      end
      
      # Verify the first was created
      get_mongo_db do |db|
        db.collection("infochimps.power.itemset").find_one({:_id => "level"})["d"].should eql ["chimpanzee", "bonobo"]
      end
      
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["foo", "bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200
          c.response.should eql ""
        end
        
        # Verify the first was clobbered
        get_mongo_db do |db|
          db.collection("infochimps.power.itemset").find_one({:_id => "level"})["d"].should eql ["foo", "bar"]
        end
      end
    end
  end
  
  context 'can handle GET requests' do
    it 'and return 404 for missing resources' do
      with_api(Vayacondios::Server) do |api|
        get_request({:path => '/v1/infochimps/itemset/missing/resource'}, err) do |c|
          c.response_header.status.should == 404
        end
      end
    end
    
    it 'and return an array for valid resources' do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["foo", "bar"]}),
          :head => { :content_type => 'application/json' }
        }, err)
      end
      with_api(Vayacondios::Server) do |api|
        get_request({:path => '/v1/infochimps/itemset/power/level'}, err) do |c|
          c.response_header.status.should == 200 
          MultiJson.load(c.response).should eql({"contents" => ["foo", "bar"]})
        end
      end
    end
  end
  
  context "will not handle POST requests" do
    it 'fails on POST' do
      with_api(Vayacondios::Server) do |api|
        post_request({
          :path => '/v1/infochimps/itemset/post/unsupported',
          :body => MultiJson.dump({ :totally => :ignored }),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should eql 405
          c.response_header["ALLOW"].should_not be_nil
        end
      end
    end
  end
  
  context "handles PATCH requests" do    
    it 'creates a missing resource' do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :head => ({'X-Method' => 'PATCH', :content_type => 'application/json' }),
          :body => MultiJson.dump({:contents =>["bar"]})
        }, err) do |c|
          c.response_header.status.should eql 200 # TODO Make this 201 Created
          c.response.should eql ""
        end
        
        # Verify the resource was created
        get_mongo_db do |db|
          db.collection("infochimps.power.itemset").find_one({:_id => "level"})["d"].should eql ["bar"]
        end
      end
    end
    
    it 'merges with PATCH' do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/merge/test',
          :body => MultiJson.dump({:contents =>["foo"]}),
          :head => { :content_type => 'application/json' }
        }, err)
      end
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/merge/test',
          :head => ({'X-Method' => 'PATCH', :content_type => 'application/json' }),
          :body => MultiJson.dump({:contents =>["bar"]})
        }, err)
      end
      with_api(Vayacondios::Server) do |api|
        get_request({:path => '/v1/infochimps/itemset/merge/test'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql({"contents" => ["foo", "bar"]})
        end
      end
    end
  end
  
  context "will handle DELETE requests" do
    it 'will not delete a missing resource' do
      with_api(Vayacondios::Server) do |api|
        delete_request({
          :path => '/v1/infochimps/itemset/merge/test',
          :body => MultiJson.dump({:contents =>["bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 404
        end
      end
    end
      
    it "will be ok to delete items that don't exist" do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["foo"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 201 Created
        end
      end
      with_api(Vayacondios::Server) do |api|
        delete_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 204 No content
        end
      end
    end
    
    it "will delete items that do exist" do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["foo", "bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Makes this 201 Created
        end
      end
      with_api(Vayacondios::Server) do |api|
        delete_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 204 No content
        end
      end
      with_api(Vayacondios::Server) do |api|
        get_request({:path => '/v1/infochimps/itemset/power/level'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql({"contents" => ["foo"]})
        end
      end
    end
    
    it "leaves behind an empty array if everything is deleted" do
      with_api(Vayacondios::Server) do |api|
        put_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["foo", "bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Makes this 201 Created
        end
      end
      with_api(Vayacondios::Server) do |api|
        delete_request({
          :path => '/v1/infochimps/itemset/power/level',
          :body => MultiJson.dump({:contents =>["foo", "bar"]}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200 # TODO Make this 204 No content
        end
      end
      with_api(Vayacondios::Server) do |api|
        get_request({:path => '/v1/infochimps/itemset/power/level'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql({"contents" => []})
        end
      end
    end
  end
end
