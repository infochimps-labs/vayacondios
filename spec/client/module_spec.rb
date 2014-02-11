require 'spec_helper'

describe Vayacondios::Client do

  context '.base_uri' do
    it 'provides a default' do
      subject.base_uri({}).should eq('http://localhost:3467/v3')
    end

    it 'allows for overrides' do
      subject.base_uri(host: 'foo.com', port: 1234).should eq('http://foo.com:1234/v3')
    end
  end

  context '.new_connection' do
    it 'creates a new faraday connection' do
      subject.new_connection.should be_a(Faraday::Connection)
    end

    it 'allows for overrides' do
      conn = subject.new_connection(log: 'foo')
      conn.builder.handlers.should include(Faraday::Response.lookup_middleware(:logger))
    end
  end

  context '.global_connection' do
    it 'returns a singleton connection' do
      subject.global_connection.should be_a(Faraday::Connection)
      subject.global_connection.should be(subject.global_connection)
    end
  end
end
