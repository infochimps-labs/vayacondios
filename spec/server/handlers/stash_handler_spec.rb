require 'spec_helper'

describe Vayacondios::StashHandler, stashes: true do
  
  let(:log)          { double("Logger", debug: true)                    }
  let(:database)     { double("Mongo::DB")                              }
  let(:params)       { { organization: 'organization', topic: 'topic' } }

  subject { Vayacondios::StashHandler.new(log, database) }

  describe "#find" do
    it "returns the record found by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:find)
        .with(log, database, params, {}).and_return(hash_stash)
      subject.find(params).should == hash_stash
    end

    it "raises a 404-error if no record is found" do
      Vayacondios::Stash.should_receive(:find)
        .with(log, database, params, {}).and_return(nil)
      expect { subject.find(params) }.to raise_error(Goliath::Validation::Error, /not found/)
    end
  end

  describe "#create" do
    it "returns the record created by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:create)
        .with(log, database, params, hash_stash).and_return(hash_stash)
      subject.create(params, hash_stash).should == hash_stash
    end
  end
  
  describe "#update" do
    it "returns the record updated by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:update)
        .with(log, database, params, hash_stash).and_return(hash_stash)
      subject.update(params, hash_stash).should == hash_stash
    end
  end
  
  describe "#patch" do
    it "returns the record patched by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:patch)
        .with(log, database, params, hash_stash).and_return(hash_stash)
      subject.patch(params, hash_stash).should == hash_stash
    end
  end
  
  describe "#destroy" do
    it "returns the record destroyed by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:destroy)
        .with(log, database, params).and_return({})
      subject.delete(params).should == {}
    end
  end
  
end
