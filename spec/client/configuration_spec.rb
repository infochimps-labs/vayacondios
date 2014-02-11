require 'spec_helper'

describe Vayacondios::Client::Configuration do
  its(:defaults) do
    should eq(host: 'localhost', port: 3467, adapter: :net_http)
  end

  it 'defines a connection options constant' do
    Vayacondios::Client::ConnectionOpts.should be_a(described_class)
  end
end
