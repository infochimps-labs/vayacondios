require 'spec_helper'

describe Vayacondios::Event, events: true do

  before { Timecop.freeze(timestamp) }
  after  { Timecop.return            }
  
  let(:organization) { 'organization'      }
  let(:topic)        { 'topic'             }
  let(:log)          { double("Logger", debug: true)    }
  let(:database)     { double("Mongo::DB") }
  let(:id)           { 'id'                }
  let(:timestamp)    { Time.now            }

  let(:collection)   { double("Mongo::Collection", name: "organization.topic.events") }
  before             { database.stub!(:collection).and_return(collection)             }

  subject { Vayacondios::Event.new(log, database, organization: organization, topic: topic) }

  describe "#collection_name" do
    its(:collection_name) { should == "organization.topic.events" }
  end
  
  describe "#to_timestamp" do

    it "given a nil value returns the current time" do
      subject.to_timestamp(nil).should == timestamp
    end

    it "given a Time instance returns that instance" do
      subject.to_timestamp(timestamp).should == timestamp
    end

    it "given a Date instance converts it into a Time" do
      # loses time information...so set to beginning of day
      subject.to_timestamp(timestamp.to_date).should == timestamp.to_date.to_time
    end
    
    it "given a String parses it into a Time" do
      # loses millisecond resolution...so round to the second
      subject.to_timestamp(timestamp.to_s).should == Time.at(timestamp.to_i) 
    end

    it "converts all times to UTC" do
      tokyo_time = timestamp.getlocal("+09:00")
      subject.to_timestamp(tokyo_time).zone.should == "UTC"
    end
    
  end

  describe "#find" do
    context "without an ID" do
      it "performs a search request" do
        subject.should_receive(:search).with(event_query)
        subject.find(event_query)
      end
    end
    context "with an ID" do
      before { subject.id = id }

      it "sends a :find_one request to the database" do
        collection.should_receive(:find_one).with(_id: id)
        subject.find
      end

      context "when an event with the given organization, topic, and ID exists" do
        before do
          collection.should_receive(:find_one)
            .with(_id: id)
            .and_return({'_id' => id, 't' => timestamp, 'd' => hash_event.merge('time' => timestamp)})
          subject.find
        end

        it "sets its timestamp from the returned event" do
          subject.timestamp.should == timestamp
        end

        it "sets its body from the returned event" do
          subject.body.should == hash_event.merge('time' => timestamp)
        end
      end

      context "when an event with the given organization, topic, and ID doesn't exist" do
        before do
          collection.should_receive(:find_one).with(_id: id).and_return(nil)
          subject.find
        end
        its(:timestamp) { should be_nil }
        its(:body)      { should be_nil }
      end
      
    end
  end

  describe "#search" do
    it "has default sorting, limiting, and windowing behavior" do
      collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
      subject.search(event_query)
    end
    it "accepts the 'sort' parameter" do
      collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar"}, sort: ['bing', 'descending'], limit: Vayacondios::Event::LIMIT)
      subject.search(event_query_with_sort)
    end
    it "accepts the 'limit' parameter" do
      collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: 10)
      subject.search(event_query_with_limit)
    end
    it "accepts the 'fields' parameter" do
      collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT, fields: %w[bing bam])
      subject.search(event_query_with_fields)
    end
    
    describe "handling 'time' parameters" do
      it "parses them when they're strings" do
        collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        subject.search(event_query_with_string_time)
      end
      it "parses them when they're numeric" do
        collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        subject.search(event_query_with_int_time)
      end
      it "ignores them when they are something else" do
        collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar", "d.time" => ["hello"]}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        subject.search(event_query.merge("time" => ['hello']))
      end
      it "ignores them when they are unparseable" do
        collection.should_receive(:find).with({"t" => {gte: kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        subject.search(event_query.merge("time" => {gte: "2013-06-73 Sat 100:35"}))
      end
      
    end
  end

  describe "#create" do
    it "raises an error when given a non-Hash" do
      expect { subject.create([]) }.to raise_error(Goliath::Validation::Error, /Hash/)
    end

    context "with an ID" do
      before { subject.id = id }
      it "sends an upsert request for the record with the given ID" do
        collection.should_receive(:update).with({:_id => id}, kind_of(Hash), {upsert: true})
        subject.create(hash_event)
      end
    end

    context "without an ID" do
      it "sends an insert request" do
        collection.should_receive(:insert).with(kind_of(Hash)).and_return(id)
        subject.create(hash_event)
      end
    end
  end

  describe '#to_mongo_create_document' do
    describe "the _id field" do
      context "for an event with an ID" do
        before  { subject.id = id }
        it "is set to the ID" do
          subject.to_mongo_create_document({})[:_id].should == id
        end
      end
      context "for an  event lacks an ID" do
        it "is not present" do
          subject.to_mongo_create_document({})[:_id].should be_nil
        end
      end
    end

    describe "the t field" do
      context "for an event with no timestamp and" do
        context "a document without a timestamp" do
          it "sets it to the current time" do
            subject.to_mongo_create_document({})[:t].should == timestamp
          end
        end
        context "a document with a timestamp" do
          it "sets it to the timestamp of the document" do
            subject.to_mongo_create_document('time' => timestamp)[:t].should == timestamp
          end
        end
      end
      context "for an event with a timestamp and" do
        before { subject.timestamp = timestamp }
        context "a document without a timestamp" do
          it "sets it to the event's time" do
            subject.to_mongo_create_document({})[:t].should == timestamp
          end
        end
        context "a document with a timestamp" do
          it "sets it to the timestamp of the document" do
            subject.to_mongo_create_document('time' => timestamp + 1)[:t].should == timestamp + 1
          end
        end
      end
    end
  end
end
