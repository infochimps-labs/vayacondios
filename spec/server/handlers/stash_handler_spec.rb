require 'spec_helper'

describe Vayacondios::StashHandler, stashes: true do
  
  let(:log)          { double("Logger", debug: true)                    }
  let(:database)     { double("Mongo::DB")                              }
  let(:params)       { { organization: 'organization', topic: 'topic' } }

  subject { Vayacondios::StashHandler.new(log, database) }

  describe "#show" do
    it "returns the record found by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:find)
        .with(log, database, params)
        .and_return(hash_stash)
      subject.show(params).should == hash_stash
    end

    it "raises a 404-error if no record is found" do
      Vayacondios::Stash.should_receive(:find)
        .with(log, database, params)
        .and_return(nil)
      expect { subject.show(params) }.to raise_error(Goliath::Validation::Error, /not found/)
    end
  end

  describe "#create" do
    it "returns the record created by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:create)
        .with(log, database, params, hash_stash)
        .and_return(hash_stash)
      subject.create(params, hash_stash).should == hash_stash
    end
  end

  describe "#replace_many" do
    it "delegates to the Stash model" do
      Vayacondios::Stash.should_receive(:replace_many)
        .with(log, database, params, stash_query, stash_replacement)
        .and_return(Vayacondios::Stash::OK)
      subject.replace_many(params, {query: stash_query, update: stash_replacement}).should == Vayacondios::Stash::OK
    end
  end
  
  describe "#update" do
    it "returns the record updated by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:update)
        .with(log, database, params, hash_stash)
        .and_return(hash_stash)
      subject.update(params, hash_stash).should == hash_stash
    end
  end

  describe "#update_many" do
    it "delegates to the Stash model" do
      Vayacondios::Stash.should_receive(:update_many)
        .with(log, database, params, stash_query, stash_update)
        .and_return(Vayacondios::Stash::OK)
      subject.update_many(params, {query: stash_query, update: stash_update}).should == Vayacondios::Stash::OK
    end
  end
  
  describe "#delete" do
    it "returns the record destroyed by the Stash model it delegates to" do
      Vayacondios::Stash.should_receive(:destroy)
        .with(log, database, params)
        .and_return(Vayacondios::Stash::OK)
      subject.delete(params).should == Vayacondios::Stash::OK
    end
  end

  describe "#delete_many" do
    it "delegates to the Stash model" do
      Vayacondios::Stash.should_receive(:destroy_many)
        .with(log, database, params, stash_query)
        .and_return(Vayacondios::Stash::OK)
      subject.delete_many(params, stash_query).should == Vayacondios::Stash::OK
    end
  end
  
end
