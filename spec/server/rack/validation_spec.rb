require 'spec_helper'

describe Vayacondios::Rack::Validation do
  let(:env){ { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded; charset=utf-8' } }               
  let(:app){ mock('app').as_null_object }
  subject  { described_class.new(app)   }     

  it 'sets @opts when created' do
    subject.instance_variable_get('@opts').should == {}
  end

  it 'returns a bad request when :vayacondios_path does not exist' do
    subject.call(env).should == [400, {}, '{"error":"Bad Request. Format path is <host>/v1/<org>/event/<topic>"}']
  end
  
  context 'valid_paths?' do
    it 'validates the :vayacondios_path' do
      subject.valid_paths?({}).should be_true
    end
  end
end
