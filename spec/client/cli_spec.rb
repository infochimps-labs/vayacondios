require 'spec_helper'
require 'vayacondios/client/cli'

describe Vayacondios::Client::CLI, events: true, stashes: true do

  let(:client)          { double('Vayacondios::Client::HttpClient', host: 'localhost', port: 9000) }
  let(:cli)             { described_class.new }
  let(:cli_error)       { Vayacondios::Client::CLI::Error }
  let(:example_response){ double :response, :success? => true, body: {} }

  before(:each) do
    cli.stub(:client).and_return(client)
    cli.stub(:display)
  end

  describe '#boot' do
    
    after{ cli.boot }
    
    it 'resolves the commandline' do
      cli.cmdline.should_receive(:resolve!)
    end
  end

  describe 'running with no arguments' do
    before{ ARGV.replace [] }

    it 'prints a help message' do
      cli.cmdline.should_receive(:dump_help)
      cli.boot
      cli.run
    end
  end
  
  describe 'running with a non-existing command argument' do
    before{ ARGV.replace ['foobar'] }

    it 'raises an error' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error)
    end
  end
  
  describe 'announce' do
    before{ ARGV.replace ['announce'] }

    it 'raises an error without a topic' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error, /topic/)
    end

    context 'with a topic' do
      before{ ARGV << 'topic' }

      it 'raises an error without an event, --file, or STDIN' do
        cli.boot
        expect{ cli.run }.to raise_error(cli_error, /event/)
      end

      context 'and an inline event' do
        before{ ARGV << json_hash_event }

        it 'announces the event' do
          client.should_receive(:announce).with('topic', hash_event, nil).and_return(example_response)
          cli.boot
          cli.run
        end

        context 'and an ID' do
          before{ ARGV << 'id' }

          it 'announces the event' do
            client.should_receive(:announce).with('topic', hash_event, 'id').and_return(example_response)
            cli.boot
            cli.run
          end
        end
      end
    end
  end

  describe 'events' do
    before{ ARGV.replace ['events'] }

    it 'raises an error without a topic' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error, /topic/)
    end

    context 'with topic' do
      before{ ARGV << 'topic' }

      it 'searches for events' do
        client.should_receive(:events).with('topic', {}).and_return(example_response)
        cli.boot
        cli.run
      end

      context 'and an inline query' do
        before{ ARGV << json_event_query }

        it 'uses the query' do
          client.should_receive(:events).with('topic', event_query).and_return(example_response)
          cli.boot
          cli.run
        end
      end
    end
  end

  describe 'get' do
    before{ ARGV.replace ['get'] }

    it 'raises an error without a topic' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error, /topic/)
    end

    context 'with a topic' do
      before{ ARGV << 'topic' }

      it 'gets the document' do
        client.should_receive(:get).with('topic', nil).and_return(example_response)
        cli.boot
        cli.run
      end

      context 'and an ID' do
        before{ ARGV << 'id' }

        it 'gets the document' do
          client.should_receive(:get).with('topic', 'id').and_return(example_response)
          cli.boot
          cli.run
        end
      end
    end
  end

  describe 'get_many' do
    before{ ARGV.replace ['get_many'] }

    it 'searches for stashes' do
      client.should_receive(:get_many).with({}).and_return(example_response)
      cli.boot
      cli.run
    end

    context 'and an inline query' do
      before{ ARGV << json_stash_query }

      it 'uses the query' do
        client.should_receive(:get_many).with(stash_query).and_return(example_response)
        cli.boot
        cli.run
      end
    end
  end

  describe 'set' do
    before{ ARGV.replace ['set'] }

    it 'raises an error without a topic' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error, /topic/)
    end

    context 'with a topic' do
      before{ ARGV << 'topic' }

      it 'raises an error without a document, --file, or STDIN' do
        cli.boot
        expect{ cli.run }.to raise_error(cli_error, /document/)
      end

      context 'and an inline document' do
        before{ ARGV << json_hash_stash }

        it 'stashes the document' do
          client.should_receive(:set).with('topic', nil, hash_stash).and_return(example_response)
          cli.boot
          cli.run
        end

        context 'and an ID' do
          before{ ARGV << 'id' }
          
          it 'stashes the document using the id' do
            client.should_receive(:set).with('topic', 'id', hash_stash).and_return(example_response)
            cli.boot
            cli.run
          end
        end
      end
    end
  end
  
  describe 'set!' do
    before{ ARGV.replace ['set!'] }

    it 'raises an error without a topic' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error, /topic/)
    end

    context 'with a topic' do
      before{ ARGV << 'topic' }

      it 'raises an error without a document, --file, or STDIN' do
        cli.boot
        expect{ cli.run }.to raise_error(cli_error, /document/)
      end

      context 'and an inline document' do
        before{ ARGV << json_hash_stash }

        it 'stashes the document ' do
          client.should_receive(:set!).with('topic', nil, hash_stash).and_return(example_response)
          cli.boot
          cli.run
        end

        context 'and an ID' do
          before{ ARGV << 'id' }

          it 'stashes the document under the id' do
            client.should_receive(:set!).with('topic', 'id', hash_stash).and_return(example_response)
            cli.boot
            cli.run
          end
        end
      end
    end
  end
  
  describe 'unset' do
    before{ ARGV.replace(['unset']) }

    it 'raises an error without a topic' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error, /topic/)
    end

    context 'with a topic' do
      before{ ARGV << 'topic' }

      it 'deletes the document' do
        client.should_receive(:unset).with('topic', nil).and_return(example_response)
        cli.boot
        cli.run
      end

      context 'and an ID' do
        before{ ARGV << 'id' }

        it 'deletes the document' do
          client.should_receive(:unset).with('topic', 'id').and_return(example_response)
          cli.boot
          cli.run
        end
      end
    end
  end

  describe 'unset_many' do
    before{ ARGV.replace ['unset_many'] }

    it 'raises an error without a document, --file or STDIN' do
      cli.boot
      expect{ cli.run }.to raise_error(cli_error)
    end

    context 'with input' do
      before{ ARGV << json_stash_query }

      it 'calls the unset_many method on the client' do
        client.should_receive(:unset_many).with(stash_query).and_return(example_response)
        cli.boot
        cli.run
      end
    end
  end  
end
