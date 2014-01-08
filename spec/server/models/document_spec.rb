require 'spec_helper'

describe Vayacondios::Server::Document do
  
  let(:organization){ 'organization' }
  let(:topic)       { 'topic' }
  let(:log)         { double("Logger") }
  let(:database)    { double("Mongo::DB") }
  let(:id)          { 'id' }
  let(:params)      { { organization: organization, topic: topic } }

  subject           { described_class.new(log, database, params) }

  its(:log)     { should == log      }
  its(:database){ should == database }    
  

  context "#initialize", "without an 'organization' option" do
    let(:params) { { topic: topic } }
    
    it "raises an error" do
      expect { described_class.new(log, database, params) }.to raise_error(Vayacondios::Server::Document::Error, /organization/)
    end
  end
  
  context '#initialize', "with 'organization' and 'topic' options" do
    let(:params) { { organization: organization, 'topic' => topic } } # symbol AND string keys

    it "sets the organization for the document" do
      described_class.new(log, database, params).organization.should == organization
    end
    
    it "sets the topic of the document" do
      described_class.new(log, database, params).topic.should == topic
    end

    it 'sets the id if present' do
      params[:id] = id 
      described_class.new(log, database, params).id.should == id
    end
  end
  
  describe "#id=" do

    let(:string){ 'aaaaaaaaaaaaaaaaaaaaaaaa' }
    let(:bson)  { BSON::ObjectId(string)     }

    it "given a nil value raises an error" do
      expect{ subject.id = nil }.to raise_error(Vayacondios::Server::Document::Error, /ID/)
    end
    
    it "given a BSON::ObjectId uses it" do
      subject.id = bson
      subject.id.should == bson
    end

    context "given a Hash" do
      it "raises an error unless the Hash contains an '$oid' value" do
        expect{ subject.id = {'foo' => 'bar'} }.to raise_error(Vayacondios::Server::Document::Error, /ID/)
      end
      
      it "uses the '$oid' value when present" do
        subject.id = { '$oid' => string }
        subject.id.should == bson
      end
    end
    
    it "given a String formatted like a BSON::ObjectId turns it into a real BSON::ObjectId" do
      subject.id = string
      subject.id.should == bson
    end
    
    it "given any other object uses its String representation" do
      subject.id = 123
      subject.id.should == '123'
    end
  end

  describe "#organization=" do
    subject{ described_class }

    it "replaces non-word characters and non-(period|hyphen|underscore)s from a topic with underscores" do
      subject.new(log, database, topic: topic, organization: 'hello-.there buddy').organization.should == 'hello-.there_buddy'
    end

    it "replaces periods from the beginning and end of a topic with underscores" do
      subject.new(log, database, topic: topic, organization: '.hello.there.').organization.should == '_hello.there_'
    end

    it "prepends an underscore to the reserved prefix 'system.'" do
      subject.new(log, database, topic: topic, organization: 'system.foobar').organization.should == '_system.foobar'
    end
  end
end
