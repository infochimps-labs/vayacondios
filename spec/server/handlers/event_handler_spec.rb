require 'spec_helper'

describe Vayacondios::Server::EventHandler, events: true do
  
  let(:log)          { double("Logger", debug: true)                    }
  let(:database)     { double("Mongo::DB")                              }
  let(:params)       { { organization: 'organization', topic: 'topic' } }

  subject { described_class.new(log, database) }

  describe "#retrieve" do
    it "returns the record found by the Server::Event model it delegates to" do
      Vayacondios::Server::Event.should_receive(:find)
        .with(log, database, params).and_return(hash_event)
      subject.retrieve(params).should == hash_event
    end

    it "raises a 404-error if no record is found" do
      Vayacondios::Server::Event.should_receive(:find)
        .with(log, database, params).and_return(nil)
      expect { subject.retrieve(params) }.to raise_error(Goliath::Validation::NotFoundError, /not found/)
    end
  end

  describe "#create" do
    it "returns the record created by the Server::Event model it delegates to" do
      Vayacondios::Server::Event.should_receive(:create)
        .with(log, database, params, hash_event).and_return(hash_event)
      subject.create(params, hash_event).should == hash_event
    end
  end

  describe "#update" do
    it "returns a 400" do
      expect { subject.update(params, hash_event) }.to raise_error(Goliath::Validation::Error, /update/)
    end
  end

  describe "#delete" do
    it "returns a 400" do
      expect { subject.delete(params) }.to raise_error(Goliath::Validation::Error, /delete/)
    end
  end
  
end
