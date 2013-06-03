require 'spec_helper'

describe Vayacondios::Stash, stashes: true do

  let(:organization) { 'organization'      }
  let(:topic)        { 'topic'             }
  let(:log)          { double("Logger", debug: true)    }
  let(:database)     { double("Mongo::DB") }
  let(:id)           { 'id'                }
  let(:timestamp)    { Time.now            }

  let(:collection)   { double("Mongo::Collection", name: "organization.stash") }
  before             { database.stub!(:collection).and_return(collection)       }

  subject { Vayacondios::Stash.new(log, database, organization: organization, topic: topic) }

  describe "#collection_name" do
    its(:collection_name) { should == "organization.stash" }
  end

  describe "#id=" do
    it "allows setting an arbitrary string ID" do
      subject.id = '.mongo. unhappy string'
      subject.id.should == '.mongo. unhappy string'
    end
    it "will not set a blank ID" do
      subject.id = ''
      subject.id.should be_nil
    end
  end

  describe "#topic=" do
    it "allows setting an arbitrary topic" do
      subject.topic = '.mongo. crazy string'
      subject.topic.should == '.mongo. crazy string'
    end
    it "will not set a blank topic" do
      subject.topic = ''
      subject.topic.should == topic
    end
  end

  describe "#find" do
    context "with an ID" do
      before { subject.id = id }
      it "sends a find_one request to the database selecting just the specific ID field" do
        collection.should_receive(:find_one).with({_id: topic}, {fields: [id]})
        subject.find
      end
      context "when a stash with the given topic exists" do
        before do
          collection.should_receive(:find_one)
            .with({_id: topic}, {fields: [id]})
            .and_return({"_id" => topic, id => hash_stash})
        end
        it "returns the value of the ID field" do
          subject.find.should == hash_stash
        end
      end
      context "when a stash with the given topic doesn't exist" do
        before do
          collection.should_receive(:find_one)
            .with({_id: topic}, {fields: [id]})
            .and_return(nil)
        end
        it "returns nil" do
          subject.find.should be_nil
        end
      end
    end
    context "without an ID" do
      it "sends a find_one request to the database for the whole record" do
        collection.should_receive(:find_one).with({_id: topic})
        subject.find
      end
      context "when a stash with the given topic exists" do
        before do
          collection.should_receive(:find_one)
            .with({_id: topic})
            .and_return(hash_stash.merge("_id" => topic))
        end
        it "returns the stash without its topic" do
          subject.find.should == hash_stash
        end
      end
      context "when a stash with the given topic doesn't exist" do
        before do
          collection.should_receive(:find_one)
            .with({_id: topic})
            .and_return(nil)
        end
        it "returns nil" do
          subject.find.should be_nil
        end
      end
    end
  end

  describe "#create" do
    context "with an ID" do
      before { subject.id = id }
      it "accepts and returns a Hash" do
        collection.should_receive(:update)
          .with({_id: topic}, {'$set' => {id => hash_stash}}, {upsert: true})
        subject.create(hash_stash).should == hash_stash
      end
      it "accepts and returns an Array" do
        collection.should_receive(:update)
          .with({_id: topic}, {'$set' => {id => array_stash}}, {upsert: true})
        subject.create(array_stash).should == array_stash
      end
      it "accepts and returns a String" do
        collection.should_receive(:update)
          .with({_id: topic}, {'$set' => {id => string_stash}}, {upsert: true})
        subject.create(string_stash).should == string_stash
      end
      it "accepts and returns a Numeric" do
        collection.should_receive(:update)
          .with({_id: topic}, {'$set' => {id => numeric_stash}}, {upsert: true})
        subject.create(numeric_stash).should == numeric_stash
      end
    end
    context "without an ID" do
      it "raises an error on a non-Hash" do
        expect { subject.create([1,2,3]) }.to raise_error(Goliath::Validation::Error, /Hash/)
      end
      it "accepts and returns a Hash" do
        collection.should_receive(:update)
          .with({_id: topic}, hash_stash.merge(_id: topic), {upsert: true})
        subject.create(hash_stash).should == hash_stash
      end
    end
  end

  describe "#update" do
    before { subject.should_receive(:find) }
    context "with an ID" do
      before { subject.id = id }
    end
    context "without an ID" do
    end
  end
  
end
