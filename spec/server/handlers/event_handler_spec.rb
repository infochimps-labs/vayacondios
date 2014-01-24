require 'spec_helper'

describe Vayacondios::Server::EventHandler, behaves_like: 'handler' do

  let(:params)     { { organization: 'organization', topic: 'topic' } }
  let(:document)   { { foo: 'bar', time: '2013-01-01T10:23:10.432Z' } }
  let(:model_class){ Vayacondios::Server::Event }

  context '#create' do
    it 'returns the created event' do
      model_class.should_receive(:create).with(params, document).and_call_original      
      driver.should_receive(:insert).and_return(_id: 'abc123')
      handler.create(params, document).should eq(id: 'abc123',
                                                   foo: 'bar',
                                                   time: '2013-01-01T10:23:10.432Z')
    end
  end

  context '#retrieve', 'when an event is found' do
    let(:params){ { organization: 'organization', topic: 'topic', id: 'abc123' } }

    it 'returns the selected event' do
      model_class.should_receive(:find).with(params).and_call_original
      driver.should_receive(:retrieve).and_return(_id: 'abc123', _t: '2013-01-01T10:23:10.432Z', _d: { foo: 'bar' })
      handler.retrieve(params, {}).should eq(id:   'abc123',
                                             foo:  'bar',
                                             time: '2013-01-01T10:23:10.432Z')
    end
  end
  
  context '#retrieve', 'when an event is not found', focus: true do
    let(:params){ { organization: 'organization', topic: 'topic', id: 'abc123' } }

    it 'raises a validation error' do
      model_class.should_receive(:find).with(params).and_call_original
      driver.should_receive(:retrieve).and_return(nil)
      expect{ handler.retrieve(params, {}) }.to raise_error(validation_error, /not found/)
    end
  end

  context '#update' do
    it 'raises a validation error' do
      expect{ handler.update(params, document) }.to raise_error(validation_error, /update/)
    end
  end

  context '#delete', 'when params have no id' do
    it 'raises a validation error' do
      expect{ handler.delete(params, {}) }.to raise_error(validation_error, /id/i)
    end
  end

  context '#delete', 'when successful' do
    let(:params){ { organization: 'organization', topic: 'topic', id: 'abc123' } }

    it 'returns success response' do
      model_class.should_receive(:destroy).with(params, {}).and_call_original      
      driver.should_receive(:remove).and_return(true)
      handler.delete(params, {}).should eq(success_response)
    end
  end  
end
