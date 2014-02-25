require 'spec_helper'

describe Vayacondios::Server::Document do

  let(:params){ { organization: 'organization', topic: 'topic', limit: 3, order: 'ascending' } }

  subject(:document){ described_class.receive(params) }

  context '.extract_query_options!' do
    let(:model) do
      klass = Class.new(document.class) do
        def self.default_query_options
          { limit: 5, order: 'descending', sort: 'time' }
        end
      end
    end

    let(:options) do
      model.extract_query_options! params
    end

    it 'removes projection params' do
      options.should have_key :limit
      options.should have_key :sort
      options.should have_key :order

      params.should_not have_key :limit
      params.should_not have_key :sort
      params.should_not have_key :order

      params.should have_key :organization
      params.should have_key :topic
    end

    it 'uses defaults' do
      options.should have_key :sort
      options[:sort].should eq 'time'
    end

    it 'uses params when provided' do
      options.should have_key :limit
      options.should have_key :order

      options[:limit].should eq 3
      options[:order].should eq 'ascending'
    end
  end

end
