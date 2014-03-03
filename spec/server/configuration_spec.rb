require 'spec_helper'

describe Vayacondios::Server::Configuration do
  its(:defaults) do
    should eq(development: {
                database: {
                  driver:      'mongo',
                  host:        'localhost',
                  port:        27017,
                  name:        'vayacondios_development',
                  connections: 20,
                }
              },
              test: {
                database: {
                  driver:      'mongo',
                  host:        'localhost',
                  port:        27017,
                  name:        'vayacondios_test',
                  connections: 20,
                }
              },
              production: {
                database: {
                  driver:      'mongo',
                  host:        'localhost',
                  port:        27017,
                  name:        'vayacondios_production',
                  connections: 20,
                }
              })
  end

  it 'defines a db config constant' do
    Vayacondios::Server::DbConfig.should be_a(described_class)
  end

  context '#env' do
    it 'allows hash access scoped by environment' do
      subject.env(:development).should eq(database: {
                                            driver:      'mongo',
                                            host:        'localhost',
                                            port:        27017,
                                            name:        'vayacondios_development',
                                            connections: 20 })
    end
  end
end
