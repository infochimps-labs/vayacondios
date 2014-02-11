require 'spec_helper'

describe Vayacondios::HttpClient do

  let(:http_connection){ double :http }
  let(:hash_event)     { { foo: 'bar' } }
  subject(:http_client){ described_class.new(organization: 'organization') }
  
  def expect_query(verb, &assertions)
    subject.http_connection.should_receive(verb) do |path, &blk|
      request = double :request
      assertions.call(path, request)
      blk.call(request) unless blk.nil?
    end
  end

  context '#initialize' do
    it 'allows to customize the connection' do
      http_client = described_class.new(host: 'foo.com')
      http_client.http_connection.url_prefix.host.should eq('foo.com')
    end
  end

  context '#announce', 'without an ID' do
    it 'constructs a POST request to /v3/organization/event/topic with the Event as the body' do
      expect_query(:post) do |path, req|
        path.should eq('organization/event/topic')
        req.should_receive(:body=).with(hash_event)
      end
      http_client.announce('topic', hash_event)
    end
  end
  
  context '#announce', 'with an ID' do
    it 'constructs a POST request to /v3/organization/event/topic/id with the Event as the body' do
      expect_query(:post) do |path, req|
        path.should eq('organization/event/topic/id')
        req.should_receive(:body=).with(hash_event)
      end
      http_client.announce('topic', hash_event, 'id')
    end
  end
  
  context '#events', 'without a query' do
    it 'constructs a GET request to /v3/organization/events/topic' do
      expect_query(:get) do |path, req|
        path.should eq('organization/events/topic')
        req.should_receive(:body=).with({})
      end
      http_client.events 'topic'
    end
  end
    
  context '#events', 'with a query' do
    let(:query){ { foo: 'bar' } }

    it 'constructs a GET request to /v3/organization/events/topic with the query as the body' do
      expect_query(:get) do |path, req|
        path.should eq('organization/events/topic')
        req.should_receive(:body=).with(query)
      end
      subject.events('topic', query)
    end
  end
  
  context '#get', 'without an ID' do
    it 'constructs a GET request to /v3/organization/stash/topic' do
      expect_query(:get) do |path, req|
        path.should eq('organization/stash/topic')
      end
      subject.get 'topic'
    end
  end
  
  context '#get', 'with an ID' do
    it 'constructs a GET request to /v3/organization/stash/topic/id' do
      expect_query(:get) do |path, req|
        path.should eq('organization/stash/topic/id')
      end
      subject.get('topic', 'id')
    end
  end

  context '#get_many', 'without a query' do
    it 'sends a GET request to /v3/organization/stashes' do
      expect_query(:get) do |path, req|
        path.should eq('organization/stashes')
        req.should_receive(:body=).with({})
      end
      subject.get_many
    end
  end
    
  context '#get_many', 'with a query' do
    let(:query){ { foo: 'bar' } }

    it 'constructs a GET request to /v3/organization/stashes with the query as the body' do
      expect_query(:get) do |path, req|
        path.should eq('organization/stashes')
        req.should_receive(:body=).with(query)
      end
      subject.get_many query
    end
  end
  
  context '#set', 'without an ID' do
    let(:stash){ { foo: 'bar' } }

    it 'constructs a PUT request to /v3/organization/stash/topic with the Stash as the body' do
      expect_query(:post) do |path, req|
        path.should eq('organization/stash/topic')
        req.should_receive(:body=).with(stash)
      end
      subject.set('topic', nil, stash)
    end
  end

  context '#set', 'with an ID' do
    let(:stash){ { foo: 'bar' } }

    it 'constructs a PUT request to /v3/organization/stash/topic/id with the Stash as the body' do
      expect_query(:post) do |path, req|
        path.should eq('organization/stash/topic/id')
        req.should_receive(:body=).with(stash)
      end
      subject.set('topic', 'id', stash)
    end
  end
  
  context '#unset', 'without an ID' do
    it 'constructs a DELETE request to /v3/organization/stash/topic' do
      expect_query(:delete) do |path, req|
        path.should eq('organization/stash/topic')
      end
      subject.unset 'topic'
    end
  end
  
  context '#unset_many' do
    let(:query){ { foo: 'bar' } }

    it 'constructs a DELETE request to /v3/organization/stashes with the query' do
      expect_query(:delete) do |path, req|
        path.should eq('organization/stashes')
        req.should_receive(:body=).with(query)
      end
      subject.unset_many query
    end
  end
end
