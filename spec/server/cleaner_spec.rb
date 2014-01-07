require 'spec_helper'
require 'vayacondios/server/cleaner'

describe Vayacondios::Cleaner do
  
  let(:now) { Time.now }

  let(:database)   { double("Mongo::Database")   }

  let(:query)      { {t: { :$gte => now } }    }

  let(:events)     { double("Mongo::Collection events") }
  let(:org1topic1) { double("Mongo::Collection org1topic1") }
  let(:org1topic2) { double("Mongo::Collection org1topic2") }
  let(:org2topic1) { double("Mongo::Collection org2topic1") }
  let(:org1)       { double("Mongo::Collection org1") }
  let(:org2)       { double("Mongo::Collection org2") }
  let(:system)     { double("Mongo::Collection system") }
  let(:other)      { double("Mongo::Collection other") }
  
  before do

    Timecop.freeze(now)
    
    subject.stub(:database).and_return(database)
    
    database.stub(:collection_names).and_return(%w[ org1.topic1.events org1.topic2.events org2.topic1.events org1.stash org2.stash vayacondios.vayacondios_cleaner.events system.indexes other ])
    database.stub(:collection).with('org1.topic1.events').and_return(org1topic1)
    database.stub(:collection).with('org1.topic2.events').and_return(org1topic2)
    database.stub(:collection).with('org2.topic1.events').and_return(org2topic1)
    database.stub(:collection).with('org1.stash').and_return(org1)
    database.stub(:collection).with('org2.stash').and_return(org2)
    database.stub(:collection).with('vayacondios.vayacondios_cleaner.events').and_return(events)
    database.stub(:collection).with('system.indexes').and_return(system)
    database.stub(:collection).with('other').and_return(other)
    
    $stdout.stub(:puts)
    $stderr.stub(:puts)
  end
  
  after     { Timecop.return      }

  subject { Vayacondios::Cleaner.new }

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

  describe "#clean" do

    before { subject.stub(:from).and_return(now) }

    after  { subject.clean }

    context "with no --matching argument" do
      context "in normal mode" do
        it "removes events from the timeframe across all events collections" do
          org1topic1.should_receive(:remove).with(query).and_return({'n' => 1})
          org1topic2.should_receive(:remove).with(query).and_return({'n' => 1})
          org2topic1.should_receive(:remove).with(query).and_return({'n' => 1})
          events.should_receive(:remove).with(query).and_return({'n' => 1})
        end
      end
      
      context "in --dry_run mode" do
        before { subject.settings[:dry_run] = true }
        it "counts evenets from the timeframe across all events collections" do
          org1topic1.should_receive(:find).with(query).and_return(double("Mongo::Cursor", count: 1))
          org1topic2.should_receive(:find).with(query).and_return(double("Mongo::Cursor", count: 1))
          org2topic1.should_receive(:find).with(query).and_return(double("Mongo::Cursor", count: 1))
          events.should_receive(:find).with(query).and_return(double("Mongo::Cursor", count: 1))
        end
      end
    end

    context "with a --matching argument" do
      before { subject.settings[:matching] = /^org1\..*\.events$/ }
      
      context "in normal mode" do
        it "removes events from the timeframe across all matching collections" do
          org1topic1.should_receive(:remove).with(query).and_return({'n' => 1})
          org1topic2.should_receive(:remove).with(query).and_return({'n' => 1})
        end
      end
      
      context "in --dry_run mode" do
        before { subject.settings[:dry_run] = true }
        it "counts evenets from the timeframe across all matching collections" do
          org1topic1.should_receive(:find).with(query).and_return(double("Mongo::Cursor", count: 1))
          org1topic2.should_receive(:find).with(query).and_return(double("Mongo::Cursor", count: 1))
        end
      end
    end
  end

  describe "#finish" do

    let(:counts) {
      [
       { collection: 'foo', count:  3},
       { collection: 'bar', count:  4}
      ]
    }
    
    before do
      subject.stub(:from).and_return(now)
      subject.stub(:counts).and_return(counts)
      events.stub(:insert)
    end
    
    after  { subject.finish }

    context "in normal mode" do
      it "announces the counts to Vayacondios" do
        events.should_receive(:insert).with(t: now, d: counts)
      end

      it "prints the counts" do
        $stdout.should_receive(:puts).with("3	foo")
        $stdout.should_receive(:puts).with("4	bar")
      end
    end

    context "in --dry_run mode" do
      before { subject.settings[:dry_run] = true }
      it "does not announce an event" do
        events.should_not_receive(:insert)
      end

      it "prints the counts" do
        $stdout.should_receive(:puts).with("3	foo")
        $stdout.should_receive(:puts).with("4	bar")
      end
    end
    
  end
  
  
end
