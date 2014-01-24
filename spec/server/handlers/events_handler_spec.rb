require 'spec_helper'

describe Vayacondios::Server::EventsHandler, behaves_like: 'handler' do
  
  let(:params)     { { organization: 'organization', topic: 'topic' } }
  let(:query)      { { foo: 'bar' } }
  let(:model_class){ Vayacondios::Server::Event }

  context '#create' do
    it 'raises a validation error' do
      expect{ handler.create(params, query) }.to raise_error(validation_error, /create/)
    end
  end

  context '#search', 'when events are found' do
    it 'returns an array of events' do
      model_class.should_receive(:search).with(params, query).and_call_original
      driver.should_receive(:search).and_return([{ _id: 'abc123', _t: '2013-01-01T08:12:23.328Z', _d: { foo: 'bar' } }])
      handler.search(params, query).should eq([
                                               {
                                                 id:   'abc123',
                                                 time: '2013-01-01T08:12:23.328Z',
                                                 foo:  'bar'
                                               }
                                              ])
    end
  end

  context '#search', 'when no events are found' do
    it 'returns an empty array' do
      model_class.should_receive(:search).with(params, query).and_call_original
      driver.should_receive(:search).and_return([])
      handler.search(params, query).should eq([])
    end
  end

  context '#update' do
    it 'raises a validation error' do
      expect{ handler.update(params, query) }.to raise_error(validation_error, /update/)
    end
  end

  context '#delete' do
    it 'returns a success response' do
      model_class.should_receive(:destroy).with(params, query).and_call_original
      driver.should_receive(:remove).and_return(true)
      handler.delete(params, query).should eq(success_response)
    end
  end
  
end
