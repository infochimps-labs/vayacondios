require 'spec_helper'

require 'multi_json'

require File.join(File.dirname(__FILE__), '../../', 'app/http_shim')

describe HttpShim do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.error}" } }

  context 'Configuration management' do
    it 'requires a topic' do
      with_api(HttpShim) do |api|
        put_request({
          :path => '/v1/infochimps/config/',
          :body => MultiJson.dump({:level=>"awesome"}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
      end
    end
    
    it 'requires an id' do
      with_api(HttpShim) do |api|
        put_request({
          :path => '/v1/infochimps/config/power',
          :body => MultiJson.dump({:level=>"awesome"}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
      end
    end
    
    it 'stores configuration' do
      with_api(HttpShim) do |api|
        put_request({
          :path => '/v1/infochimps/config/power/level',
          :body => MultiJson.dump({:level=>"awesome"}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 200
        end
        
        get_mongo_db do |db|
          db.collection("infochimps.config").find_one({:_id => "power"}).should eql({"_id" => "power", "level" => "awesome"})
        end
      end
    end
    
    it 'rejects deep IDs' do
      with_api(HttpShim) do |api|
        put_request({
          :path => '/v1/infochimps/config/power/level/is/invalid',
          :body => MultiJson.dump({:level=>"awesome"}),
          :head => { :content_type => 'application/json' }
        }, err) do |c|
          c.response_header.status.should == 400
        end
        
        get_mongo_db do |db|
          db.collection("infochimps.config").find_one({:_id => "power"}).should be_nil
        end
      end
    end
    
    it 'retrieves configuration' do
      with_api(HttpShim) do |api|
        put_request({
          :path => '/v1/infochimps/config/power/level',
          :body => MultiJson.dump({:level=>"awesome"}),
          :head => { :content_type => 'application/json' }
        }, err)
      end
      with_api(HttpShim) do |api|
        get_request({:path => '/v1/infochimps/config/power/level'}, err) do |c|
          c.response_header.status.should == 200 
          MultiJson.load(c.response).should eql({"level" => "awesome"})
        end
      end
    end
    
    it 'merge deep configuration' do
      with_api(HttpShim) do |api|
        put_request({
          :path => '/v1/infochimps/config/merge/test',
          :body => MultiJson.dump({ :foo => { :bar => 3 } }),
          :head => { :content_type => 'application/json' }
        }, err)
      end
      with_api(HttpShim) do |api|
        put_request({
          :path => '/v1/infochimps/config/merge/test',
          :body => MultiJson.dump({ :foo => { :baz => 7 } }),
          :head => { :content_type => 'application/json' }
        }, err)
      end
      with_api(HttpShim) do |api|
        get_request({:path => '/v1/infochimps/config/merge/test'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql({
            "foo" => {
              "bar" => 3,
              "baz" => 7
            }
          })
        end
      end
    end
  end
end
