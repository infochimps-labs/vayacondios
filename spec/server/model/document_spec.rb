require 'spec_helper'

describe Vayacondios::Document do
  
  let(:organization) { 'organization' }
  let(:topic)        { 'topic'        }
  
  subject { Vayacondios::Document }
  
  describe "#initialize" do
    
    context "without an 'organization' option" do
      let(:params) { {topic: topic} }
      it "raises an error" do
        expect { subject.new(params) }.to raise_error(Vayacondios::Document::Error, /organization/)
      end
    end
    
    context "without a 'topic' option" do
      let(:params) { {organization: organization} }
      it "raises an error" do
        expect { subject.new(params) }.to raise_error(Vayacondios::Document::Error, /topic/)
      end
    end

    context "with 'organization' and 'topic' options" do
      let(:params) { {organization: organization, 'topic' => topic} } # symbol AND string keys
      it "sets the organization for the document" do
        subject.new(params).organization.should == organization
      end
      it "sets the topic of the document" do
        subject.new(params).topic.should == topic
      end
    end
  end
  
end
