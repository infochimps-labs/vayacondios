require 'spec_helper'

describe Vayacondios::MongoDocument do

  let(:organization) { 'organization'      }
  let(:topic)        { 'topic'             }
  let(:log)          { double("Logger")    }
  let(:database)     { double("Mongo::DB") }
  let(:id)           { 'id'                }

  subject { Vayacondios::MongoDocument }
  
  describe "#initialize" do
    let(:params)   { { organization: organization, topic: topic }          }
    subject        { Vayacondios::MongoDocument.new(log, database, params) }
    
    its(:log)      { should == log      }
    its(:database) { should == database }

    context "with an 'id' option" do
      before   { params[:id] = id }
      its(:id) { should == id }
    end
  end
  
  describe "#id=" do

    let(:string)   { 'aaaaaaaaaaaaaaaaaaaaaaaa' }
    let(:bson)     { BSON::ObjectId(string)     }
    let(:document) { Vayacondios::MongoDocument.new(log, database, organization: organization, topic: topic) }

    it "given a nil value raises an error" do
      expect { document.id = nil }.to raise_error(Vayacondios::Document::Error, /ID/)
    end
    
    it "given a BSON::ObjectId uses it" do
      document.id = bson
      document.id.should == bson
    end

    context "given a Hash" do
      it "raises an error unless the Hash contains an '$oid' value" do
        expect { document.id = {'foo' => 'bar'} }.to raise_error(Vayacondios::Document::Error, /ID/)
      end
      
      it "uses the '$oid' value when present" do
        document.id = { '$oid' => string }
        document.id.should == bson
      end
    end
    
    it "given a String formatted like a BSON::ObjectId turns it into a real BSON::ObjectId" do
      document.id = string
      document.id.should == bson
    end
    
    it "given any other object uses its String representation" do
      document.id = 123
      document.id.should == '123'
    end
  end

  describe "#topic=" do
    it "replaces non-word characters, non-(period|hyphen|underscore)s from a topic with underscores" do
      Vayacondios::MongoDocument.new(log, database, organization: organization, topic: 'hello-.there buddy').topic.should == 'hello-.there_buddy'
    end
    it "replaces periods from the beginning and end of a topic with underscores" do
      Vayacondios::MongoDocument.new(log, database, organization: organization, topic: '.hello.there.').topic.should == '_hello.there_'
    end
  end

  describe "#organization=" do
    it "replaces non-word characters and non-(period|hyphen|underscore)s from a topic with underscores" do
      Vayacondios::MongoDocument.new(log, database, topic: topic, organization: 'hello-.there buddy').organization.should == 'hello-.there_buddy'
    end
    it "replaces periods from the beginning and end of a topic with underscores" do
      Vayacondios::MongoDocument.new(log, database, topic: topic, organization: '.hello.there.').organization.should == '_hello.there_'
    end
  end
  
end

    
      
