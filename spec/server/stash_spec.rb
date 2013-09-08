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
    context "/v2/organization/stashes" do
      let(:path) { "/v2/organization/stashes" }
      context "when no stashes match" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with a response body that is an empty array" do
          vcd(verb: verb, path: path, equals: [])
        end
      end
      context "when some stashes match" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.stash").insert({_id: "topic-#{i}"}.merge(hash_stash))
            end
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with a response body that includes each matching stash" do
          vcd(verb: verb, path: path, body: {topic: "^topic"}, includes: 3.times.map { |i| {"topic" => "topic-#{i}"}.merge(hash_stash) })
        end
      end
      context "when projecting down into nested stashes" do
        before do
          mongo_query do |db|
            db.collection("organization.stash").insert({_id: "topic"}.merge(nested_stash))
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, body: nested_stash_query, status: 200)
        end
        it "returns an Array of the matched stashes" do
          vcd(verb: verb, path: path, body: nested_stash_query, includes: nested_stash.merge('topic' => 'topic'))
        end
        it "allows projecting down onto the fields of the matched stashes" do
          vcd(verb: verb, path: path, body: nested_stash_query.merge(fields: ["root.b"]), includes: {"root" => {"b" => 2}}.merge('topic' => 'topic'))
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
        it "stores the stash in the organization.stash collection with _id field given by the topic" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
        it "stores the stash in the organization.stash collection with the _id field given by the topic" do
          vcd(verb: verb, body: hash_stash, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
          vcd(verb: verb, path: path, body: hash_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
          vcd(verb: verb, path: path, body: array_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
          vcd(verb: verb, path: path, body: string_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
          vcd(verb: verb, path: path, body: nil_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
            stash['id'].should == {}
          end
        end
      end
    end
    
    context "/v2/organization/stashes" do
      let(:path) { "/v2/organization/stashes" }
      context "with an empty request body" do
        it "should return a 400" do
          vcd(verb: verb, path: path, status: 400)
        end
        it "with an error message telling you the query can't be missing" do
          vcd(verb: verb, path: path, error: /query.*empty/i)
        end
      end
      context "with a malformed query" do
        it "should return a 400" do
          vcd(verb: verb, path: path, body: {query: "hello"}, status: 400)
        end
        it "with an error message telling you the query must be a Hash" do
          vcd(verb: verb, path: path, body: {query: "hello"},error: /query.*hash/i)
        end
      end
      context "with an empty query" do
        it "should return a 400" do
          vcd(verb: verb, path: path, body: {query: {}}, status: 400)
        end
        it "with an error message telling you the query can't be empty" do
          vcd(verb: verb, path: path, body: {query: {}}, error: /query.*empty/i)
        end
      end
      context "when the query doesn't match any stashes" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.stash").insert({_id: "topic-#{i}"}.merge(hash_stash))
            end
          end
        end
        let(:body) { {query: {'foo' => 'bing'}, update: {'foo' => 'bong'}} }
        it "should return a 200" do
          vcd(verb: verb, path: path, body: body, status: 200)
        end
        it "no stashes should be modified" do
          vcd(verb: verb, path: path, body: body)
          mongo_query do |db|
            stashes = db.collection("organization.stash").find().to_a
            stashes.should_not be_nil
            stashes.size.should == 3
            stashes.each { |stash| stash['foo'].should == 'bar' }
          end
        end
      end
      context "when the query does match some stashes" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.stash").insert({_id: "topic-#{i}"}.merge(hash_stash))
            end
          end
        end
        let(:body) { {query: stash_query, update: stash_replacement} }
        it "should return a 200" do
          vcd(verb: verb, path: path, body: body, status: 200)
        end
        it "each stash should be modified in place" do
          vcd(verb: verb, path: path, body: body)
          mongo_query do |db|
            stashes = db.collection("organization.stash").find().to_a
            stashes.should_not be_nil
            stashes.size.should == 3
            stashes.each { |stash| stash['foo'].should == stash_replacement['foo'] }
          end
        end
      end
    end
  end

  context "PUT" do
    let(:verb) { "PUT" }
    context "/v2/organization/stash/topic" do
      let(:path) { "/v2/organization/stash/topic" }
      context "with an empty stash" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "with an empty Hash" do
          vcd(verb: verb, path: path, equals: {})
        end
        it "stores the stash in the organization.stash collection with _id field given by the topic" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
        it "stores the stash in the organization.stash collection with the _id field given by the topic" do
          vcd(verb: verb, body: hash_stash, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
            stash['id'].should == nil
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
          vcd(verb: verb, path: path, body: hash_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
          vcd(verb: verb, path: path, body: array_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
          vcd(verb: verb, path: path, body: string_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
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
          vcd(verb: verb, path: path, body: nil_stash)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
            stash['id'].should == nil
          end
        end
      end
    end
    
    context "/v2/organization/stashes" do
      let(:path) { "/v2/organization/stashes" }
      context "with an empty request body" do
        it "should return a 400" do
          vcd(verb: verb, path: path, status: 400)
        end
        it "with an error message telling you the query can't be missing" do
          vcd(verb: verb, path: path, error: /query.*empty/i)
        end
      end
      context "with a malformed query" do
        it "should return a 400" do
          vcd(verb: verb, path: path, body: {query: "hello"}, status: 400)
        end
        it "with an error message telling you the query must be a Hash" do
          vcd(verb: verb, path: path, body: {query: "hello"},error: /query.*hash/i)
        end
      end
      context "with an empty query" do
        it "should return a 400" do
          vcd(verb: verb, path: path, body: {query: {}}, status: 400)
        end
        it "with an error message telling you the query can't be empty" do
          vcd(verb: verb, path: path, body: {query: {}}, error: /query.*empty/i)
        end
      end
      context "when the query doesn't match any stashes" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.stash").insert({_id: "topic-#{i}"}.merge(hash_stash))
            end
          end
        end
        let(:body) { {query: {'foo' => 'bing'}, update: {'foo' => 'bong'}} }
        it "should return a 200" do
          vcd(verb: verb, path: path, body: body, status: 200)
        end
        it "no stashes should be modified" do
          vcd(verb: verb, path: path, body: body)
          mongo_query do |db|
            stashes = db.collection("organization.stash").find().to_a
            stashes.should_not be_nil
            stashes.size.should == 3
            stashes.each { |stash| stash['foo'].should == 'bar' }
          end
        end
      end
      context "when the query does match some stashes" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.stash").insert({_id: "topic-#{i}"}.merge(hash_stash))
            end
          end
        end
        let(:body) { {query: stash_query, update: stash_replacement} }
        it "should return a 200" do
          vcd(verb: verb, path: path, body: body, status: 200)
        end
        it "each stash should be modified in place" do
          vcd(verb: verb, path: path, body: body)
          mongo_query do |db|
            stashes = db.collection("organization.stash").find().to_a
            stashes.should_not be_nil
            stashes.size.should == 3
            stashes.each { |stash| stash['foo'].should == stash_replacement['foo'] }
          end
        end
      end
    end
  end

  context "DELETE" do
    let(:verb) { "DELETE" }
    context "/v2/organization/stash/topic" do
      let(:path) { "/v2/organization/stash/topic" }
      context "when the stash doesn't exist" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
      end
      context "when the stash exists" do
        before do
          mongo_query do |db|
            db.collection("organization.stash").insert(_id: "topic", "foo" => "bar")
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "destroys the corresponding stash record" do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            db.collection("organization.stash").find_one(_id: "topic").should be_nil
          end
        end
      end
    end
    
    context "/v2/organization/stash/topic/id" do
      let(:path) { "/v2/organization/stash/topic/id" }
      context "when the stash with the topic doesn't exist" do
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
      end
      context "when the stash with the topic exists but the ID doesn't exist" do
        before do
          mongo_query do |db|
            db.collection("organization.stash").insert(_id: "topic")
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "does not destroy any records in the database" do
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one(_id: "topic")
            stash.should_not be_nil
          end
        end
      end
      context "when the stash with the topic exists and the ID also exists" do
        before do
          mongo_query do |db|
            db.collection("organization.stash").insert(_id: "topic", id: "hello")
          end
        end
        it "returns a 200" do
          vcd(verb: verb, path: path, status: 200)
        end
        it "deletes the corresponding ID field in the stash " do
          vcd(verb: verb, path: path)
          mongo_query do |db|
            stash = db.collection("organization.stash").find_one({_id: 'topic'})
            stash['id'].should == nil
          end
        end
      end
    end
    context "/v2/organization/stashes" do
      let(:path) { "/v2/organization/stashes" }
      context "with an empty query" do
        it "should return a 400" do
          vcd(verb: verb, path: path, status: 400)
        end
        it "with an error message telling you the query can't be empty" do
          vcd(verb: verb, path: path, error: /query.*empty/i)
        end
      end
      context "when the query doesn't match any stashes" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.stash").insert({_id: "topic-#{i}"}.merge(hash_stash))
            end
          end
        end
        let(:body) { {'foo' => 'bing'} }
        it "should return a 200" do
          vcd(verb: verb, path: path, body: body, status: 200)
        end
        it "no stashes should be modified" do
          vcd(verb: verb, path: path, body: body)
          mongo_query do |db|
            stashes = db.collection("organization.stash").find().to_a
            stashes.should_not be_nil
            stashes.size.should == 3
            stashes.each { |stash| stash['foo'].should == 'bar' }
          end
        end
      end
      context "when the query does match some stashes" do
        before do
          mongo_query do |db|
            3.times do |i|
              db.collection("organization.stash").insert({_id: "topic-#{i}"}.merge(hash_stash))
            end
          end
        end
        it "should return a 200" do
          vcd(verb: verb, path: path, body: stash_query, status: 200)
        end
        it "each matching stash should be deleted" do
          vcd(verb: verb, path: path, body: stash_query)
          mongo_query do |db|
            stashes = db.collection("organization.stash").find().to_a
            stashes.should be_empty
          end
        end
      end
    end
  end
end
