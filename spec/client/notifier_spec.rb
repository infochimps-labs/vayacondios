require 'vayacondios-client'

require 'spec_helper'

class FakeModel
  include Vayacondios::Notifications
end

describe FakeModel do
  context 'including', Vayacondios::Notifications do

    it 'defines an instance method notify()' do
      subject.should respond_to(:notify)
    end

    it 'adds a configurable attribute :notifier with default' do
      subject.notifier.should be_instance_of(Vayacondios.default_notifier.class)
    end

  end
end

describe Vayacondios::Notifier do

  shared_examples_for described_class do
    it{ should respond_to(:notify) }
  end

  context '.prepare' do
    context 'given a Hash-like object' do
      let(:hashlike) { double :hashlike, :to_hash => {} }
      it 'returns a Hash' do
        subject.prepare(hashlike).should be_instance_of(Hash)
      end
    end

    context 'given a bad argument' do
      let(:bad_arg) { 'shazam' }
      it 'raises an ArgumentError' do
        expect{ subject.prepare(bad_arg) }.to raise_error(ArgumentError, /Cannot notify.*#{bad_arg}.*require a hash-like object/)
      end
    end
  end

end

describe Vayacondios::HttpNotifier do
  it_behaves_like Vayacondios::Notifier

  its(:client){ should be_instance_of(Vayacondios::HttpClient) }

  context '#notify' do
    let(:test_client) { double :client }
    let(:topic)       { 'weeeeeeeeeee' }
    let(:cargo)       { Hash.new       }

    before do
      subject.stub(:client).and_return(test_client)
      subject.stub(:prepare).and_return(cargo)
    end

    it 'notifies its client correctly' do
      test_client.should_receive(:insert).with(cargo, :event, topic)
      subject.notify(topic, cargo)
    end
  end
end

describe Vayacondios::LogNotifier do
  it_behaves_like Vayacondios::Notifier

  its(:client){ should be_instance_of(Logger) }

  context '#notify' do
    let(:test_client) { double :client }
    let(:topic)       { 'weeeeeeeeeee' }
    let(:cargo)       { Hash.new       }

    before do
      subject.stub(:client).and_return(test_client)
      subject.stub(:prepare).and_return(cargo)
    end

    it 'notifies its client correctly' do
      test_client.should_receive(:info).with(/Notification.*#{topic}/)
      subject.notify(topic, cargo)
    end
  end

end

describe Vayacondios::NotifierFactory do
  context '.receive' do
    context 'given :http' do
      it 'builds a HttpNotifier' do
        described_class.receive(type: 'http').should be_instance_of(Vayacondios::HttpNotifier)
      end
    end

    context 'given :log' do
      it 'builds a LogNotifier' do
        described_class.receive(type: 'log').should be_instance_of(Vayacondios::LogNotifier)
      end
    end

    context 'given a bad argument' do
      it 'raises an ArgumentError' do
        expect{ described_class.receive(type: 'bad') }.to raise_error(ArgumentError, /not a valid build option/)
      end
    end
  end
end

describe Vayacondios do

  it 'has a class method notify()' do
    described_class.should respond_to(:notify)
  end

end
