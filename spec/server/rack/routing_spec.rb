require 'spec_helper'

describe Vayacondios::Rack::Routing, rack: true do

  subject { described_class.new(upstream) }

  it "parses the request path and generates the route before calling the upstream app" do
    upstream.should_receive(:call)
      .with(env.merge({
                        Goliath::Request::REQUEST_PATH => "/v1/organization/event/topic",
                        vayacondios_route: kind_of(Hash),
                        'async.callback' => kind_of(Proc),
                      }))
      .and_return([200, {}, ['']])
    subject.should_receive(:parse_path).with("/v1/organization/event/topic").and_return({})
    subject.call(env.merge(Goliath::Request::REQUEST_PATH => "/v1/organization/event/topic"))
  end

  describe "#parse_path" do
    it 'returns nil if the route is unparseable' do
      subject.parse_path('/what/the:f/happened&here?').should be nil
    end

    it 'parses /v1/organization/event/topic' do
      subject.parse_path('/v1/organization/event/topic').should include(organization: 'organization', type: 'event', topic: 'topic')
    end

    it 'parses /v1/infochimps/event/topic/id' do
      subject.parse_path('/v1/organization/event/topic/id').should include(organization: 'organization', type: 'event', topic: 'topic', id: 'id')
    end

    it 'parses /v1/infochimps/events/topic' do
      subject.parse_path('/v1/organization/events/topic').should include(organization: 'organization', type: 'events', topic: 'topic')
    end

    it 'parses /v1/infochimps/stash/topic' do
      subject.parse_path('/v1/organization/stash/topic').should include(organization: 'organization', type: 'stash', topic: 'topic')
    end

    it 'parses /v1/infochimps/stash/topic/id' do
      subject.parse_path('/v1/organization/stash/topic/id').should include(organization: 'organization', type: 'stash', topic: 'topic', id: 'id')
    end

    it 'parses /v1/infochimps/stashes' do
      subject.parse_path('/v1/organization/stashes').should include(organization: 'organization', type: 'stashes')
    end
    
  end
end
