require 'spec_helper'
require 'vayacondios/client/cli'

describe Vayacondios::CLI, events: true, stashes: true do

  let(:topic) { 'topic' }
  let(:id)    { 'id'    }

  let(:client) { double("Vayacondios::HttpClient", host: 'localhost', port: 9000) }
  let(:cli)    { Vayacondios::CLI.new }

  before do
    cli.stub!(:client).and_return(client)
  end

  describe "#boot" do
    
    before do
      File.stub!(:exist?).and_return(false)
      File.stub!(:expand_path).and_return('/home/vayacondios/.vayacondios.yml')
    end

    after { cli.boot }
    
    it "resolves the settings" do
      cli.settings.should_receive(:resolve!)
    end
    
    context "when /etc/vayacondios/vayacondios.yml exists" do
      before { File.should_receive(:exist?).with("/etc/vayacondios/vayacondios.yml").and_return(true) }
      it "is read for settings" do
        cli.settings.should_receive(:read).with("/etc/vayacondios/vayacondios.yml")
      end
    end
    context "when /etc/vayacondios/vayacondios.yml doesn't exist" do
      before { File.should_receive(:exist?).with("/etc/vayacondios/vayacondios.yml").and_return(false) }
      it "is not read for settings" do
        cli.settings.should_not_receive(:read).with("/etc/vayacondios/vayacondios.yml")
      end
    end
    context "when ~/.vayacondios.yml exists" do
      before { File.should_receive(:exist?).with("/home/vayacondios/.vayacondios.yml").and_return(true) }
      it "is read for settings" do
        cli.settings.should_receive(:read).with("/home/vayacondios/.vayacondios.yml")
      end
    end
    context "when ~/.vayacondios.yml doesn't exist" do
      before { File.should_receive(:exist?).with("/home/vayacondios/.vayacondios.yml").and_return(false) }
      it "is not read for settings" do
        cli.settings.should_not_receive(:read).with("/home/vayacondios/.vayacondios.yml")
      end
    end
  end
  

  describe "running with no arguments" do
    before { ARGV.replace([]) }
    it "prints a help message" do
      cli.settings.should_receive(:dump_help)
      cli.boot
      cli.run
    end
  end
  
  describe "running with a non-existing command argument" do
    before { ARGV.replace(['foobar']) }
    it "raises an error" do
      cli.boot
      expect { cli.run }.to raise_error(Vayacondios::CLI::Error)
    end
  end
  
  describe "announce" do
    before { ARGV.replace(['announce']) }

    it "raises an error without a topic" do
      cli.boot
      expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /topic/)
    end

    context "with a topic" do
      before { ARGV << topic }
      it "raises an error without an event, --file, or STDIN" do
        cli.boot
        expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /event/)
      end

      context "and an inline event" do
        before { ARGV << json_hash_event }
        it "announces the event" do
          client.should_receive(:announce).with(topic, hash_event, nil)
          cli.boot
          cli.run
        end

        context "and an ID" do
          before { ARGV << id }
          it "announces the event" do
            client.should_receive(:announce).with(topic, hash_event, id)
            cli.boot
            cli.run
          end
        end
      end
    end
  end

  describe "events" do
    before { ARGV.replace(['events']) }
    it "raises an error without a topic" do
      cli.boot
      expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /topic/)
    end

    context "with topic" do
      before { ARGV << topic }
      it "searches for events" do
        client.should_receive(:events).with(topic, {})
        cli.boot
        cli.run
      end

      context "and an inline query" do
        before { ARGV << json_event_query }
        it "uses the query" do
          client.should_receive(:events).with(topic, event_query)
          cli.boot
          cli.run
        end
      end
    end
  end

  describe "get" do
    before { ARGV.replace(['get']) }

    it "raises an error without a topic" do
      cli.boot
      expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /topic/)
    end

    context "with a topic" do
      before { ARGV << topic }
      it "gets the document" do
        client.should_receive(:get).with(topic, nil)
        cli.boot
        cli.run
      end
      context "and an ID" do
        before { ARGV << id }
        it "gets the document" do
          client.should_receive(:get).with(topic, id)
          cli.boot
          cli.run
        end
      end
    end
  end

  describe "stashes" do
    before { ARGV.replace(['stashes']) }
    it "searches for stashes" do
      client.should_receive(:stashes).with({})
      cli.boot
      cli.run
    end
    context "and an inline query" do
      before { ARGV << json_stash_query }
      it "uses the query" do
        client.should_receive(:stashes).with(stash_query)
        cli.boot
        cli.run
      end
    end
  end

  describe "set" do
    before { ARGV.replace(['set']) }

    it "raises an error without a topic" do
      cli.boot
      expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /topic/)
    end

    context "with a topic" do
      before { ARGV << topic }
      it "raises an error without a document, --file, or STDIN" do
        cli.boot
        expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /document/)
      end

      context "and an ID" do
        before { ARGV << id }
        
        context "and an inline document" do
          before { ARGV << json_hash_stash }
          it "stashes the document " do
            client.should_receive(:set).with(topic, id, hash_stash)
            cli.boot
            cli.run
          end
        end
      end
      
      context "and a blank ID" do
        before { ARGV << '-' }
        context "and an inline document" do
          before { ARGV << json_hash_stash }
          it "stashes the document " do
            client.should_receive(:set).with(topic, nil, hash_stash)
            cli.boot
            cli.run
          end
        end
      end
    end
  end

  describe "set!" do
    before { ARGV.replace(['set!']) }

    it "raises an error without a topic" do
      cli.boot
      expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /topic/)
    end

    context "with a topic" do
      before { ARGV << topic }
      it "raises an error without a document, --file, or STDIN" do
        cli.boot
        expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /document/)
      end

      context "and an ID" do
        before { ARGV << id }
        
        context "and an inline document" do
          before { ARGV << json_hash_stash }
          it "stashes the document " do
            client.should_receive(:set!).with(topic, id, hash_stash)
            cli.boot
            cli.run
          end
        end
      end
      
      context "and a blank ID" do
        before { ARGV << '-' }
        context "and an inline document" do
          before { ARGV << json_hash_stash }
          it "stashes the document " do
            client.should_receive(:set!).with(topic, nil, hash_stash)
            cli.boot
            cli.run
          end
        end
      end
    end
  end

  describe "delete" do
    before { ARGV.replace(['delete']) }

    it "raises an error without a topic" do
      cli.boot
      expect { cli.run }.to raise_error(Vayacondios::CLI::Error, /topic/)
    end

    context "with a topic" do
      before { ARGV << topic }
      it "deletes the document" do
        client.should_receive(:delete).with(topic, nil)
        cli.boot
        cli.run
      end
      context "and an ID" do
        before { ARGV << id }
        it "deletes the document" do
          client.should_receive(:delete).with(topic, id)
          cli.boot
          cli.run
        end
      end
    end
  end
  
end
