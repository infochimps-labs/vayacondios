require 'spec_helper'

describe Vayacondios::Server::StashesHandler, stashes: true do
  
  let(:log)          { double("Logger", debug: true)                    }
  let(:database)     { double("Mongo::DB")                              }
  let(:params)       { { organization: 'organization', topic: 'topic' } }

  subject { described_class.new(log, database) }

  describe "#create" do
    it "delegates to the Stash model" do
      Vayacondios::Server::Stash.should_receive(:replace_many)
        .with(log, database, params, stash_query, stash_replacement)
        .and_return(Vayacondios::Server::Stash::OK)
      subject.create(params, {query: stash_query, update: stash_replacement}).should == Vayacondios::Server::Stash::OK
    end
  end

  describe "#retrieve" do
    it "returns the record found by the Stash model it delegates to" do
      Vayacondios::Server::Stash.should_receive(:search)
        .with(log, database, params, query: stash_query)
        .and_return(hash_stash)
      subject.retrieve(params, query: stash_query).should == hash_stash
    end
  end

  describe "#update" do
    it "delegates to the Stash model" do
      Vayacondios::Server::Stash.should_receive(:update_many)
        .with(log, database, params, stash_query, stash_update)
        .and_return(Vayacondios::Server::Stash::OK)
      subject.update(params, {query: stash_query, update: stash_update}).should == Vayacondios::Server::Stash::OK
    end
  end

  describe "#delete" do
    it "delegates to the Stash model" do
      Vayacondios::Server::Stash.should_receive(:destroy_many)
        .with(log, database, params, stash_query)
        .and_return(Vayacondios::Server::Stash::OK)
      subject.delete(params, stash_query).should == Vayacondios::Server::Stash::OK
    end
  end
  
end
