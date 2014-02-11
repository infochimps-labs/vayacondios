require 'spec_helper'

describe Vayacondios::Server::ApiOptions do

  let(:api) do
    api_options = described_class
    Class.new{ include api_options }.new
  end
  let(:settings){ Hash.new }
  let(:parser)  { OptionParser.new }

  it 'sets the default config file location' do
    api.options_parser(parser, settings)
    settings[:config].should eq(File.join(Vayacondios.library_dir, 'config/vcd-server.rb'))
  end

  it 'sets the default server port' do
    api.options_parser(parser, settings)
    settings[:port].should eq(3467)
  end

  it 'allows commandline overrides for database options' do
    ARGV.replace %w[-d foo -h foo.com -D bar -o 1234 -n 10]
    api.options_parser(parser, settings)
    parser.parse!
    settings[:database].should eq(driver:      'foo',
                                  connections: 10,
                                  host:        'foo.com',
                                  name:        'bar',
                                  port:        1234)
  end
end
