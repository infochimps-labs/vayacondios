require 'spec_helper'

describe Vayacondios::Server::EventsHandler, events: true do
  
  let(:log)          { double("Logger", debug: true)                    }
  let(:database)     { double("Mongo::DB")                              }
  let(:params)       { { organization: 'organization', topic: 'topic' } }

  subject { described_class.new(log, database) }

  describe "#retrieve" do
    it "returns the record created by the Server::Event model it delegates to" do
      Vayacondios::Server::Event.should_receive(:search)
        .with(log, database, params, hash_event).and_return(hash_event)
      subject.retrieve(params, hash_event).should == hash_event
    end
  end

  describe "#create" do
    it "returns a 405" do
      expect { subject.update(params, hash_event) }.to raise_error(Goliath::Validation::Error, /update/)
    end
  end

  describe "#update" do
    it "returns a 405" do
      expect { subject.update(params, hash_event) }.to raise_error(Goliath::Validation::Error, /update/)
    end
  end

  describe "#delete" do
    it "returns a 405" do
      expect { subject.delete(params) }.to raise_error(Goliath::Validation::Error, /delete/)
    end
  end
  
end
