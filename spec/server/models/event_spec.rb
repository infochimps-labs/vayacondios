require 'spec_helper'

describe Vayacondios::Event, events: true do

  before { Timecop.freeze(timestamp) }
  after  { Timecop.return            }
  
  let(:organization) { 'organization'      }
  let(:topic)        { 'topic'             }
  let(:id)           { 'id'                }
  let(:params)       { {topic: topic, organization: organization, id: id} }
  let(:log)          { double("Logger", debug: true)    }
  let(:database)     { double("Mongo::DB") }
  let(:timestamp)    { Time.now            }
  let(:collection)   { double("Mongo::Collection", name: "organization.topic.events") }
  before             { database.stub!(:collection).and_return(collection)             }

  subject { Vayacondios::Event.new(log, database, organization: organization, topic: topic) }

  describe "#collection_name" do
    its(:collection_name) { should == "organization.topic.events" }
  end

  describe "#topic=" do
    it "replaces non-word characters, non-(period|hyphen|underscore)s from a topic with underscores" do
      Vayacondios::Event.new(log, database, organization: organization, topic: 'hello-.there buddy').topic.should == 'hello-.there_buddy'
    end
    it "replaces periods from the beginning and end of a topic with underscores" do
      Vayacondios::Event.new(log, database, organization: organization, topic: '.hello.there.').topic.should == '_hello.there_'
    end
  end
  
  describe ".to_timestamp" do

    it "returns nil when the timestamp can't be parsed" do
      Vayacondios::Event.to_timestamp(nil).should be_nil
    end
    
    it "given a default value returns the default value when the timestamp can't be parsed" do
      Vayacondios::Event.to_timestamp(nil, 'hello').should == 'hello'
    end

    it "given a Time instance returns that instance" do
      Vayacondios::Event.to_timestamp(timestamp).should == timestamp
    end

    it "given a Date instance converts it into a Time" do
      # loses time information...so set to beginning of day
      Vayacondios::Event.to_timestamp(timestamp.to_date).should == timestamp.to_date.to_time
    end
    
    it "given a String parses it into a Time" do
      # loses millisecond resolution...so round to the second
      Vayacondios::Event.to_timestamp(timestamp.to_s).should == Time.at(timestamp.to_i) 
    end

    it "given a Numeric parses it into a Time" do
      Vayacondios::Event.to_timestamp(timestamp.to_i).should == Time.at(timestamp.to_i) 
    end
    
    it "converts all times to UTC" do
      tokyo_time = timestamp.getlocal("+09:00")
      Vayacondios::Event.to_timestamp(tokyo_time).zone.should == "UTC"
    end
    
  end

  describe "#find" do
    context "without an ID" do
      it "raises an error" do
        expect { subject.find }.to raise_error(Vayacondios::Document::Error, /ID/)
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

  describe ".search" do
    it "has default sorting, limiting, and windowing behavior" do
      collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
      Vayacondios::Event.search(log, database, params, event_query)
    end
    it "accepts the 'sort' parameter" do
      collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: ['bing', 'descending'], limit: Vayacondios::Event::LIMIT)
      Vayacondios::Event.search(log, database, params, event_query_with_sort)
    end
    it "accepts the 'limit' parameter" do
      collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: 10)
      Vayacondios::Event.search(log, database, params, event_query_with_limit)
    end
    it "accepts the 'fields' parameter" do
      collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT, fields: %w[d.bing d.bam t _id])
      Vayacondios::Event.search(log, database, params, event_query_with_fields)
    end
    it "interprets the 'id' field as a regular expression search on _id" do
      collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "_id" => Regexp.new(/baz/), "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
      Vayacondios::Event.search(log, database, params, event_query_with_id)
    end
    
    
    describe "handling 'time' parameters" do
      it "parses them when they're strings" do
        collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        Vayacondios::Event.search(log, database, params, event_query_with_string_time)
      end
      it "parses them when they're numeric" do
        collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        Vayacondios::Event.search(log, database, params, event_query_with_int_time)
      end
      it "ignores them when they are something else" do
        collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        Vayacondios::Event.search(log, database, params, event_query.merge("from" => ['hello']))
      end
      it "ignores them when they are unparseable" do
        collection.should_receive(:find).with({t:  {:$gte => kind_of(Time)}, "d.foo" => "bar"}, sort: Vayacondios::Event::SORT, limit: Vayacondios::Event::LIMIT)
        Vayacondios::Event.search(log, database, params, event_query.merge("from" => "2013-06-73 Sat 100:35"))
      end
      
    end
  end

  describe "#create" do
    it "raises an error when given a non-Hash" do
      expect { subject.create([]) }.to raise_error(Vayacondios::Document::Error, /Hash/)
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

  describe '#format_event_for_mongodb' do
    describe "the _id field" do
      context "for an event with an ID" do
        before  { subject.id = id }
        it "is set to the ID" do
          subject.format_event_for_mongodb({})[:_id].should == id
        end
      end
      context "for an  event lacks an ID" do
        it "is not present" do
          subject.format_event_for_mongodb({})[:_id].should be_nil
        end
      end
    end

    describe "the t field" do
      context "for an event with no timestamp and" do
        context "a document without a timestamp" do
          it "sets it to the current time" do
            subject.format_event_for_mongodb({})[:t].should == timestamp
          end
        end
        context "a document with a timestamp" do
          it "sets it to the timestamp of the document" do
            subject.format_event_for_mongodb('time' => timestamp)[:t].should == timestamp
          end
        end
      end
      context "for an event with a timestamp and" do
        before { subject.timestamp = timestamp }
        context "a document without a timestamp" do
          it "sets it to the event's time" do
            subject.format_event_for_mongodb({})[:t].should == timestamp
          end
        end
        context "a document with a timestamp" do
          it "sets it to the timestamp of the document" do
            subject.format_event_for_mongodb('time' => timestamp + 1)[:t].should == timestamp + 1
          end
        end
      end
    end
  end
end
