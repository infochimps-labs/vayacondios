require 'spec_helper'

describe Vayacondios::Rack::Validation, rack: true do

  subject { described_class.new(upstream) }

  it "validates the route before calling upstream" do
    subject.should_receive(:validate_route).with(stash_route)
    subject.call(env.merge(vayacondios_route: stash_route))
  end

  describe "#validate_route" do
    it "raises en error on a nil route" do
      expect { subject.validate_route(nil) }.to raise_error(Goliath::Validation::Error, /path like/)
    end
    it "raises en error on an empty route" do
      expect { subject.validate_route({}) }.to raise_error(Goliath::Validation::Error, /path like/)
    end
    it "raises an error when missing an organization" do
      expect { subject.validate_route({type: 'hello'}) }.to raise_error(Goliath::Validation::Error, /organization/)
    end
    it "raises an error when missing a type" do
      expect { subject.validate_route({organization: 'organization'}) }.to raise_error(Goliath::Validation::Error, /type/)
    end
    it "raises an error with an unknown type" do
      expect { subject.validate_route({organization: 'organization', type: 'hello'}) }.to raise_error(Goliath::Validation::Error, /type/)
    end

    it "raises an error for a stash without a topic" do
      expect { subject.validate_route({organization: 'organization', type: 'stash'}) }.to raise_error(Goliath::Validation::Error, /topic/)
    end
    it "raises an error for an event without a topic" do
      expect { subject.validate_route({organization: 'organization', type: 'event'}) }.to raise_error(Goliath::Validation::Error, /topic/)
    end
    it "raises an error for events without a topic" do
      expect { subject.validate_route({organization: 'organization', type: 'events'}) }.to raise_error(Goliath::Validation::Error, /topic/)
    end
    
    
  end
end
