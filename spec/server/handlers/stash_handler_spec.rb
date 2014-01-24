require 'spec_helper'

describe Vayacondios::Server::StashHandler, behaves_like: 'handler' do

  let(:params)     { { organization: 'organization', topic: 'topic' } }
  let(:document)   { { foo: 'bar' } }
  let(:model_class){ Vayacondios::Server::Stash }

  context '#create' do
    it 'returns the created stash' do
      model_class.should_receive(:create).with(params, document).and_call_original
      driver.should_receive(:insert).and_return(_id: 'topic', foo: 'bar')
      handler.create(params, document).should eq(foo: 'bar')
    end
  end

  context '#retrieve', 'when not found' do
    it 'raises a validation error' do
      driver.should_receive(:retrieve).and_return(nil)
      expect{ handler.retrieve(params, {}) }.to raise_error(validation_error, /not found/)
    end
  end

  context '#retrieve', 'when params have no id' do
    it 'returns the selected record' do
      model_class.should_receive(:find).with(params).and_call_original
      driver.should_receive(:retrieve).and_return(_id: 'topic', id: { foo: 'bar' })
      handler.retrieve(params, {}).should eq(id: { foo: 'bar' })
    end
  end
  
  context '#retrieve', 'when params have an id' do
    let(:params){ { organization: 'organization', topic: 'topic', id: 'id' } }
    
    it 'returns the selected record sliced by id' do
      model_class.should_receive(:find).with(params).and_call_original
      driver.should_receive(:retrieve).and_return(_id: 'topic', id: { foo: 'bar' })
      handler.retrieve(params, {}).should eq(foo: 'bar')
    end

    it 'raises a validation error when retrieved record does not have id as a key' do
      driver.should_receive(:retrieve).and_return(_id: 'topic', id2: { foo: 'bar' })
      expect{ handler.retrieve(params, {}) }.to raise_error(validation_error, /contain id/i)
    end
  end
  
  context '#update' do
    it 'raises a validation error' do
      expect{ handler.update(params, document) }.to raise_error(validation_error, /update/)
    end
  end
  
  context '#delete', 'when params have an id' do
    let(:params){ { organization: 'organization', topic: 'topic', id: 'id' } }

    it 'raises a validation error' do
      expect{ handler.delete(params, {}) }.to raise_error(validation_error, /not supported/)
    end
  end
    
  context '#delete', 'when params do not have an id' do
    it 'returns a success response' do
      model_class.should_receive(:destroy).with(params, {}).and_call_original
      driver.should_receive(:remove).and_return(true)
      handler.delete(params, {}).should eq(success_response)
    end
  end
end
