require 'spec_helper'
require 'vayacondios/server/cleaner'

describe Vayacondios::Cleaner do

  let(:now) { Time.now }
  before    { Timecop.freeze(now) }
  after     { Timecop.return      }

  subject { Vayacondios:: Cleaner.new }

  describe "#validate" do
    it "raises an error when no --from or --upto are specified" do
      expect { subject.validate }.to raise_error(Vayacondios::Cleaner::Error, /--from.*--upto/)
    end

    it "raises an error when --from is after --upto" do
      subject.from = now
      subject.upto = now - 3600
      expect { subject.validate }.to raise_error(Vayacondios::Cleaner::Error, /--from.*earlier.*--upto/)
    end
  end

  describe "#parse_time" do

    it "parses the string 'now'" do
      subject.parse_time('now').should == now.utc
    end

    it "parses local time strings into UTC times" do
      subject.parse_time(now.to_s).should == Time.at(now.to_i).utc
    end

    it "parses relative time strings into UTC times" do
      subject.parse_time('10').should == (now - 10).utc
      subject.parse_time('30s').should == (now - 30).utc
      subject.parse_time('4h30m').should == (now - ((4 * 3600) + 1800)).utc
      subject.parse_time('90d').should == (now - (90 * 86400)).utc
    end

    it "raises an error on an unparseable string" do
      expect { subject.parse_time('foobar') }.to raise_error(Vayacondios::Cleaner::Error, /foobar/)
    end
  end
  
end
