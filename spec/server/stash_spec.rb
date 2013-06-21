require 'spec_helper'

describe Vayacondios::HttpServer, stashes: true do
  include Goliath::TestHelper

  context "GET" do
    let(:verb) { 'GET' }
    context "/v2/organization/stash/topic" do
      let(:path) { "/v2/organization/stash/topic" }
      context "if the stash isn't found" do
        it "returns a 404" do
          vcd(verb: verb, path: path, status: 404)
        end
      end
      context "if the stash is found" do
        before do
          mongo_query do |db|
            db.collection("organization.stash").insert({_id: "topic"}.merge(hash_stash))
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with the body of the stash" do
          vcd(verb: verb, path: path, includes: hash_stash)
        end
      end
    end
    context "/v2/organization/stash/topic/id" do
      let(:path) { "/v2/organization/stash/topic/id" }
      context "if the stash isn't found" do
        it "returns a 404" do
          vcd(verb: verb, path: path, status: 404)
        end
      end
      context "if the stash is found" do
        before do
          mongo_query do |db|
            db.collection("organization.stash").insert({_id: "topic", "id" => hash_stash})
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with the body of the stash" do
          vcd(verb: verb, path: path, includes: hash_stash)
        end
      end
    end
  end

  context "POST" do
    let(:verb) { "POST" }
    context "/v2/organization/stash/topic" do
      let(:path) { "/v2/organization/stash/topic" }
      context "with an empty stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with an empty Hash" do
          vcd(verb: verb, path: path, equals: {})
        end
        it "stores the stash in the organization.stash collection with the topic as the _id" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'}, sort: {t: -1})
            stash.should == { '_id' => 'topic' }
          end
        end
      end
      context "with a Hash stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, body: hash_stash, status: 200)
        end
        it "with the stash" do
          vcd(verb: verb, path: path, body: hash_stash, equals: hash_stash)
        end
        it "stores the stash in the organization.stash collection with the topic as the _id" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'}, sort: {t: -1})
            stash.should == hash_stash.merge('_id' => 'topic')
          end
        end
      end
      context "with a non-Hash" do
        it "returns a 400" do
          vcd(verb: verb, path: path, body: array_stash, status: 400)
        end
        it "with an error message explaining that you need to use hashes" do
          vcd(verb: verb, path: path, body: array_stash, error: /hash/i)
        end
        it "does not store any stashes in the organization.stash collection" do
          vcd(verb: verb, path: path, body: array_stash)
          mongo_query do |db|
            db.collection("organization.stash").count.should == 0
          end
        end
      end
    end
    
    context "/v2/organization/stash/topic/id" do
      let(:path) { "/v2/organization/stash/topic/id" }
      context "with an empty stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with an empty Hash" do
          vcd(verb: verb, path: path, equals: {})
        end
        it "stores the stash in the organization.stash collection as the ID field of the record with the topic as _id" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'}, sort: {t: -1})
            stash['id'].should == {}
          end
        end
      end
      context "with a Hash stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, body: hash_stash, status: 200)
        end
        it "with the stash" do
          vcd(verb: verb, path: path, body: hash_stash, equals: hash_stash)
        end
        it "stores the stash in the organization.stash collection as the ID field of the record with the topic as _id" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'}, sort: {t: -1})
            stash['id'].should == hash_stash
          end
        end
      end
      context "with an Array stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, body: array_stash, status: 200)
        end
        it "with the stash" do
          vcd(verb: verb, path: path, body: array_stash, equals: array_stash)
        end
        it "stores the stash in the organization.stash collection as the ID field of the record with the topic as _id" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'}, sort: {t: -1})
            stash['id'].should == array_stash
          end
        end
      end
      context "with an String stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, body: string_stash, status: 200)
        end
        it "with the stash" do
          vcd(verb: verb, path: path, body: string_stash, equals: string_stash)
        end
        it "stores the stash in the organization.stash collection as the ID field of the record with the topic as _id" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'}, sort: {t: -1})
            stash['id'].should == string_stash
          end
        end
      end
      context "with a nil stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, body: nil_stash, status: 200)
        end
        it "with the stash" do
          vcd(verb: verb, path: path, body: nil_stash, equals: nil_stash)
        end
        it "stores the stash in the organization.stash collection as the ID field of the record with the topic as _id" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'}, sort: {t: -1})
            stash['id'].should == nil
          end
        end
      end
    end
  end
end

    
    

#   context 'Configuration management' do
#     it 'requires a topic' do
#       with_api(Vayacondios::HttpServer) do |api|
#         put_request({
#           :path => '/v2/infochimps/config/',
#           :body => MultiJson.dump({:level=>"awesome"}),
#           :head => { :content_type => 'application/json' }
#         }, err) do |c|
#           c.response_header.status.should == 400
#         end
#       end
#     end
    
#     it 'requires an id' do
#       with_api(Vayacondios::HttpServer) do |api|
#         put_request({
#           :path => '/v2/infochimps/config/power',
#           :body => MultiJson.dump({:level=>"awesome"}),
#           :head => { :content_type => 'application/json' }
#         }, err) do |c|
#           c.response_header.status.should == 400
#         end
#       end
#     end
    
#     it 'stores configuration' do
#       with_api(Vayacondios::HttpServer) do |api|
#         put_request({
#           :path => '/v2/infochimps/config/power/level',
#           :body => MultiJson.dump({:level=>"awesome"}),
#           :head => { :content_type => 'application/json' }
#         }, err) do |c|
#           c.response_header.status.should == 200
#         end
        
#         get_mongo_db do |db|
#           db.collection("infochimps.config").find_one({:_id => "power"}).should eql({"_id" => "power", "level" => "awesome"})
#         end
#       end
#     end
    
#     it 'rejects deep IDs' do
#       with_api(Vayacondios::HttpServer) do |api|
#         put_request({
#           :path => '/v2/infochimps/config/power/level/is/invalid',
#           :body => MultiJson.dump({:level=>"awesome"}),
#           :head => { :content_type => 'application/json' }
#         }, err) do |c|
#           c.response_header.status.should == 400
#         end
        
#         get_mongo_db do |db|
#           db.collection("infochimps.config").find_one({:_id => "power"}).should be_nil
#         end
#       end
#     end
    
#     it 'retrieves configuration' do
#       with_api(Vayacondios::HttpServer) do |api|
#         put_request({
#           :path => '/v2/infochimps/config/power/level',
#           :body => MultiJson.dump({:level=>"awesome"}),
#           :head => { :content_type => 'application/json' }
#         }, err)
#       end
#       with_api(Vayacondios::HttpServer) do |api|
#         get_request({:path => '/v2/infochimps/config/power/level'}, err) do |c|
#           c.response_header.status.should == 200 
#           MultiJson.load(c.response).should eql({"level" => "awesome"})
#         end
#       end
#     end
    
#     it 'merge deep configuration' do
#       with_api(Vayacondios::HttpServer) do |api|
#         put_request({
#           :path => '/v2/infochimps/config/merge/test',
#           :body => MultiJson.dump({ :foo => { :bar => 3 } }),
#           :head => { :content_type => 'application/json' }
#         }, err)
#       end
#       with_api(Vayacondios::HttpServer) do |api|
#         put_request({
#           :path => '/v2/infochimps/config/merge/test',
#           :body => MultiJson.dump({ :foo => { :baz => 7 } }),
#           :head => { :content_type => 'application/json' }
#         }, err)
#       end
#       with_api(Vayacondios::HttpServer) do |api|
#         get_request({:path => '/v2/infochimps/config/merge/test'}, err) do |c|
#           c.response_header.status.should == 200
#           MultiJson.load(c.response).should eql({
#             "foo" => {
#               "bar" => 3,
#               "baz" => 7
#             }
#           })
#         end
#       end
#     end
#   end
# end
