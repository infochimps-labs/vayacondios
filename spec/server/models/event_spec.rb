require 'spec_helper'

describe Vayacondios::Server::Event do

  let(:params)        { { topic: 'topic', organization: 'organization', id: 'id' } }
  let(:now)           { event.format_time Time.now }
  let(:document_error){ Vayacondios::Server::Document::Error }

  subject(:event){ described_class.receive params }
  
  its(:location){ should eq('organization.topic.events') }

  context '#receive_topic' do
    it 'sanitizes the topic' do
      event.receive_topic '.foo$bar'
      event.topic.should eq('_foo_bar')
    end
  end

  context '#receive_time' do
    it 'formats the time' do
      event.receive_time '2014-01-23T15:29:19.412412-06:00'
      event.time.should be_a(Time)
      event.time.should be_utc
    end
  end

  context '#to_timestamp', 'when argument is a string' do
    it 'returns a time' do
      event.to_timestamp('Aug 31').should be_a(Time)
    end

    it 'returns the default when there is parse error' do
      default = now
      event.to_timestamp('foobar', default).should be(default)
    end
  end

  context '#to_timestamp', 'when argument is a date' do
    it 'returns a time' do
      event.to_timestamp(Date.today).should be_a(Time)
    end
  end

  context '#to_timestamp', 'when argument is a time' do
    it 'returns the time argument' do
      t = now
      event.to_timestamp(t).should be(t)
    end
  end

  context '#to_timestamp', 'when argument is numeric' do
    it 'returns a time' do
      event.to_timestamp(1390513812).should be_a(Time)
    end
  end

  context '#to_timestamp', 'when argument is anything else' do
    it 'returns the default' do
      default = now
      event.to_timestamp(Object.new, default).should be(default)
    end
  end

  context '#format_time' do
    it 'converts all time to UTC' do
      tokyo_time = now.getlocal('+09:00')
      event.format_time(tokyo_time).should be_utc
    end

    it 'rounds all time to milliseconds' do
      precise_time = Time.at(1390514371.671_238_912)
      event.format_time(precise_time).nsec.should eq(671_000_000)
    end
  end

  context '#document' do
    it 'returns the internal representation of this Event' do
      event.receive!(time: now, body: { foo: 'bar' })
      event.document.should eq(_id: 'id',
                               _t:  now,
                               _d:  { foo: 'bar' })
    end
  end

  context '#from_document' do
    it 'updates the Event with the document' do
      updated = event.from_document(_t: now, _d: { foo: 'bar' })
      updated.id.should   eq('id')
      updated.time.should eq(now)
      updated.body.should eq(foo: 'bar')
    end
  end

  context '#external_document' do
    it 'returns the external representation of this Event' do
      event.receive!(time: now, body: { foo: 'bar' })
      event.external_document.should eq(id:   'id', 
                                        time: now.iso8601(3),
                                        foo:  'bar')
    end
  end

  context '#event_filter' do
    it 'handles :after as greater than' do
      event.event_filter(after: now).should eq(_t: { gt: now })
    end

    it 'handles :from as greater than or equal to' do
      event.event_filter(from: now).should eq(_t: { gte: now })
    end

    it 'prioritizes :after over :from' do
      event.event_filter(after: now, from: now).should eq(_t: { gt: now })
    end

    it 'handles :before as less than' do
      event.event_filter(before: now).should eq(_t: { lt: now })
    end

    it 'handles :upto as less than or equal to' do
      event.event_filter(upto: now).should eq(_t: { lte: now })
    end

    it 'prioritizes :before over :upto' do
      event.event_filter(before: now, upto: now).should eq(_t: { lt: now })
    end

    it 'merges extra keys as data matchers' do
      event.event_filter(foo: 'bar', before: now).should eq(_t: { lt: now }, _d: { foo: 'bar' })
    end
  end

  context '#prepare_search', focus: true do
    it 'returns self for chaining' do
      event.prepare_search({}).should be(event)
    end

    it 'creates a filter based on the query' do
      prepared = event.prepare_search(foo: 'bar', before: now)
      prepared.filter.should eq(_t: { lt: now }, _d: { foo: 'bar' })
    end
  end

  context '#prepare_find', focus: true do
    it 'returns self for chaining' do
      event.prepare_find.should be(event)
    end

    it 'raises an error if it was not created with an id' do
      event.write_attribute(:id, nil)
      expect{ event.prepare_find }.to raise_error(document_error, /id/i)
    end

    it 'returns itself' do
      event.prepare_find.document.should eq(_id: 'id')
    end
  end

  context '#prepare_create', focus: true do
    it 'returns self for chaining' do
      event.prepare_create({}).should be(event)
    end

    it 'raises an error when given a non-Hash' do
      expect{ subject.prepare_create([]) }.to raise_error(document_error, /Hash/)
    end

    it 'sets the time and body of the event' do
      prepared = event.prepare_create(time: now, foo: 'bar')
      prepared.document.should eq(_id: 'id', _t: now, _d: { foo: 'bar' })
    end
  end

  context '#prepare_destroy', focus: true do
    it 'returns self for chaining' do
      event.prepare_destroy({}).should be(event)
    end

    it 'creates a filter based on the query' do
      prepared = event.prepare_destroy(foo: 'bar', before: now)
      prepared.filter.should eq(_t: { lt: now }, _d: { foo: 'bar' })
    end
  end
end
