require 'spec_helper'

describe Vayacondios::Server::StashesHandler, behaves_like: 'handler' do

  let(:params)     { { organization: 'organization', topic: 'topic' } }
  let(:query)      { { foo: 'bar' } }
  let(:model_class){ Vayacondios::Server::Stash }

  context '#create' do
    it 'raises a validation error' do
      expect{ handler.create(params, query) }.to raise_error(validation_error, /create not allowed/)
    end
  end

  context '#retrieve', 'when no stashes are found' do
    it 'returns an empty array' do
      model_class.should_receive(:search).with(params, query).and_call_original
      driver.should_receive(:search).and_return([])
      handler.retrieve(params, query).should eq([])
    end
  end

  context '#retrieve', 'when stashes are found' do
    it "returns the record found by the Stash model it delegates to" do
      model_class.should_receive(:search).with(params, query).and_call_original
      driver.should_receive(:search).and_return([{ _id: 'topic', foo: 'bar' }])
      handler.retrieve(params, query).should eq([{ topic: 'topic', foo: 'bar' }])
    end
  end

  context '#update' do
    it 'raises a validation error' do
      expect{ handler.update(params, query) }.to raise_error(validation_error, /update not allowed/)
    end
  end

  context '#delete', 'with an empty query', focus: true do
    it 'raises a validation error' do
      expect{ handler.delete(params, {}) }.to  raise_error(validation_error, /empty/)
    end
  end

  context '#delete', 'with a query', focus: true do
    it 'returns a success response' do
      model_class.should_receive(:destroy).with(params, query).and_call_original
      driver.should_receive(:remove).and_return(true)
      handler.delete(params, query).should eq(success_response)
    end
  end
end
