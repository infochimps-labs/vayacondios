require 'spec_helper'

describe Vayacondios::EventHandler, events: true do
  
  let(:log)          { double("Logger", debug: true)                    }
  let(:database)     { double("Mongo::DB")                              }
  let(:params)       { { organization: 'organization', topic: 'topic' } }

  subject { Vayacondios::EventHandler.new(log, database) }

  describe "#find" do
    it "returns the record found by the Event model it delegates to" do
      Vayacondios::Event.should_receive(:find)
        .with(log, database, params, {}).and_return(hash_event)
      subject.find(params).should == hash_event
    end

    it "raises a 404-error if no record is found" do
      Vayacondios::Event.should_receive(:find)
        .with(log, database, params, {}).and_return(nil)
      expect { subject.find(params) }.to raise_error(Goliath::Validation::Error, /not found/)
    end
  end

  describe "#create" do
    it "returns the record created by the Event model it delegates to" do
      Vayacondios::Event.should_receive(:create)
        .with(log, database, params, hash_event).and_return(hash_event)
      subject.create(params, hash_event).should == hash_event
    end
  end

  describe "#update" do
    it "returns a 400" do
      expect { subject.update(params, hash_event) }.to raise_error(Goliath::Validation::Error, /update/)
    end
  end

  describe "#patch" do
    it "returns a 400" do
      expect { subject.patch(params, hash_event) }.to raise_error(Goliath::Validation::Error, /patch/)
    end
  end

  describe "#delete" do
    it "returns a 400" do
      expect { subject.delete(params) }.to raise_error(Goliath::Validation::Error, /delete/)
    end
  end
  
end
