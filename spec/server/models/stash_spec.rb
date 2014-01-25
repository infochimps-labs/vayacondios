require 'spec_helper'

describe Vayacondios::Server::Stash, stashes: true do

  let(:params)        { { topic: 'topic', organization: 'organization', id: 'id' } }
  let(:document_error){ Vayacondios::Server::Document::Error }

  subject(:stash){ described_class.receive params }

  its(:location){ should eq('organization.stash') }

  context '#document' do
    it 'returns the internal representation of this stash' do
      stash.receive!(body: { foo: 'bar' })
      stash.document.should eq(_id: 'topic', foo: 'bar')
    end
  end

  context '#from_document' do
    it 'updates the stash with the document' do
      updated = stash.from_document(_id: 'qix', foo: 'bar')
      updated.document.should eq(_id: 'qix', foo: 'bar')
    end
  end

  context '#external_document' do
    it 'returns the external representation of this stash' do
      stash.receive!(body: { foo: 'bar' })
      stash.external_document.should eq(topic: 'topic', foo: 'bar')
    end
  end
  
  context '#prepare_search' do
    it 'returns itself for chaining' do
      stash.prepare_search({}).should be(stash)
    end

    it 'prepares a search filter' do
      prepared = stash.prepare_search(foo: 'bar')
      prepared.filter.should eq(_id: 'topic', foo: 'bar')
    end
  end

  context '#prepare_create' do
    it 'returns itself for chaining' do
      stash.prepare_create({}).should be(stash)
    end
  end

  context '#prepare_create', 'without an id' do
    before(:each){ stash.write_attribute(:id, nil) }

    it 'raises an error if document is not a Hash' do
      expect{ stash.prepare_create([]) }.to raise_error(document_error, /hash/i)
    end

    it 'sets :body to be the document' do
      prepared = stash.prepare_create(foo: 'bar')
      prepared.body.should eq(foo: 'bar')
    end
  end

  context '#prepare_create', 'with an id' do
    it 'sets :body to be the document' do
      prepared = stash.prepare_create(foo: 'bar')
      prepared.body.should eq('id' => { foo: 'bar' })
    end
  end

  context '#prepare_find' do
    it 'returns itself for chaining' do
      stash.prepare_find.should be(stash)
    end

    it 'raises an error if there is no topic' do
      stash.write_attribute(:topic, nil)
      expect{ stash.prepare_find }.to raise_error(document_error, /topic/)
    end

    it 'returns itself' do
      stash.prepare_find.document.should eq(_id: 'topic')
    end
  end

  context '#prepare_destroy' do
    it 'returns itself for chaining' do
      stash.prepare_destroy({}).should be(stash)
    end

    it 'prepares a delete filter' do
      prepared = stash.prepare_destroy(foo: 'bar')
      prepared.filter.should eq(_id: 'topic', foo: 'bar')
    end
  end
end
