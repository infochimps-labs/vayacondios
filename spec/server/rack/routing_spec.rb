require 'spec_helper'

describe Vayacondios::Rack::Routing do
  let(:env) { { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded; charset=utf-8' } }
  let(:app) { mock('app').as_null_object }
  subject   { described_class.new(app)   }     

  it 'adds a key in env for :vayacondios_route' do
    app.should_receive(:call).with do |app_env|
      app_env.keys.should include(:vayacondios_route)
    end
    subject.call(env)
  end
  
  context 'parse_path' do
    it 'returns nil if the route is unparseable' do
      subject.parse_path('/what/the:f/happened&here?').should be nil
    end
    it 'parses organizations and types correctly' do
      subject.parse_path('/v1/infochimps/event').should include(organization: 'infochimps', type: 'event')
    end

    it 'parses topics correctly' do
      subject.parse_path('/v1/infochimps/config/foo').should include(topic: 'foo')
    end

    it 'parses ids correctly' do
      subject.parse_path('/v1/infochimps/itemset/bar/1').should include(id: '1')
    end

    it 'parses formats correctly' do
      subject.parse_path('/v1/infochimps/event/baz/1.json').should include(format: 'json')
    end
  end
end
