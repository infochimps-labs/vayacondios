require 'spec_helper'

describe Vayacondios::Client, events: true, stashes: true do
  
  let(:organization) { 'organization' }
  let(:topic)        { 'topic'        }
  let(:id)           { 'id'           }
  
  subject { Vayacondios::Client.new(organization: organization) }

  describe "#announce" do
    it "is defined" do
      should respond_to(:announce)
    end

    context "without arguments" do
      it "raises an error" do
        expect { subject.announce() }.to raise_error(ArgumentError)
      end
    end

    context "with only a topic argument" do
      it "announces the event for the given topic without specifying an ID" do
        expect { subject.announce(topic) }.to_not raise_error
      end
      it "announces the event for the given topic without specifying an ID" do
        expect { subject.announce(topic: topic) }.to_not raise_error
      end
    end

    context "with a topic and a Hash event" do
      it "announces the event for the given topic without specifying an ID" do
        expect { subject.announce(topic, hash_event) }.to_not raise_error
      end
      it "announces the event for the given topic without specifying an ID" do
        expect { subject.announce(topic: topic, event: hash_event) }.to_not raise_error
      end
    end

    context "with a topic and an Array event" do
      it "announces the event" do
        expect { subject.announce(topic, array_event) }.to_not raise_error
      end
      it "announces the event" do
        expect { subject.announce(topic: topic, event: array_event) }.to_not raise_error
      end
    end

    context "with a topic and an String event" do
      it "announces the event" do
        expect { subject.announce(topic, string_event) }.to_not raise_error
      end
      it "announces the event" do
        expect { subject.announce(topic: topic, event: string_event) }.to_not raise_error
      end
    end

    context "with a topic, event, and ID" do
      it "announces the event" do
        expect { subject.announce(topic, string_event, id) }.to_not raise_error
      end
      it "announces the event" do
        expect { subject.announce(topic: topic, event: string_event, id: id) }.to_not raise_error
      end
    end
  end

  describe "#get" do
    it "is defined" do
      should respond_to(:get)
    end

    context "without arguments" do
      it "raises an error" do
        expect { subject.get() }.to raise_error(ArgumentError)
      end
    end

    context "with only a topic argument" do
      it "gets the value stashed for the given topic" do
        expect { subject.get(topic) }.to_not raise_error
      end
      it "gets the value stashed for the given topic" do
        expect { subject.get(topic: topic) }.to_not raise_error
      end
      
    end

    context "with a topic and an ID" do
      it "gets the value statshed for the given ID within the given topic" do
        expect { subject.get(topic, id) }.to_not raise_error
      end
      it "gets the value statshed for the given ID within the given topic" do
        expect { subject.get(topic: topic, id: id) }.to_not raise_error
      end
      
    end
  end

  describe "#set" do
    it "is defined" do
      should respond_to(:set)
    end

    context "without arguments" do
      it "raises an error" do
        expect { subject.set() }.to raise_error(ArgumentError)
      end
    end

    context "with topic, ID, and a value" do
      it "sets the value for the given topic and ID" do
        expect { subject.set(topic, id, hash_stash) }.to_not raise_error
      end
      it "sets the value for the given topic and ID" do
        expect { subject.set(topic: topic, id: id, value: hash_stash) }.to_not raise_error
      end
    end
  end


  describe "#set!" do
    it "is defined" do
      should respond_to(:set!)
    end

    context "without arguments" do
      it "raises an error" do
        expect { subject.set!() }.to raise_error(ArgumentError)
      end
    end

    context "with topic, ID, and a value" do
      it "sets the value for the given topic and id" do
        expect { subject.set!(topic, id, hash_stash) }.to_not raise_error
      end
      it "sets the value for the given topic and id" do
        expect { subject.set!(topic: topic, id: id, value: hash_stash) }.to_not raise_error
      end
    end
  end

  describe "#delete" do
    it "is defined" do
      should respond_to(:delete)
    end

    context "without arguments" do
      it "raises an error" do
        expect { subject.delete() }.to raise_error(ArgumentError)
      end
    end

    context "with only a topic argument" do
      it "deletes the value stashed for the given topic" do
        expect { subject.delete(topic) }.to_not raise_error
      end
      it "deletes the value stashed for the given topic" do
        expect { subject.delete(topic: topic) }.to_not raise_error
      end
    end

    context "with a topic and an ID" do
      it "deletes the value stashed for the given ID within the given topic" do
        expect { subject.delete(topic, id) }.to_not raise_error
      end
      it "deletes the value stashed for the given ID within the given topic" do
        expect { subject.delete(topic: topic, id: id) }.to_not raise_error
      end
    end
  end
  
  
end
