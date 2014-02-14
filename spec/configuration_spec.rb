require 'spec_helper'

describe Vayacondios::Configuration do

  def change_defaults new_defaults
    subject.define_singleton_method(:defaults) do
      new_defaults
    end
  end

  context '#defaults' do
    it 'defines defaults' do
      subject.defaults.should eq(Hash.new)
    end
  end

  context '#resolved_settings' do
    it 'resolves settings automatically when accessed' do
      subject.should_not be_resolved
      subject.resolved_settings.should eq(Hash.new)
      subject.should be_resolved
    end
  end

  context '#overlay' do
    before{ change_defaults(foo: 'bar', baz: 'qix') }

    it 'allows a top-level override of settings' do
      subject.overlay(foo: 'override')
      subject.resolved_settings.should eq(foo: 'override', baz: 'qix')
    end
  end

  context '#[]' do
    before{ change_defaults(foo: 'bar') }

    it 'allows access to the resolved_settings' do      
      subject[:foo].should eq('bar')
    end
  end
end
