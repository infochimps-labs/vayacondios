shared_context 'rack', rack: true do
  
  before(:each) do
    env.stub(:logger).and_return(logger)
  end

  let(:upstream) do
    Proc.new do |env|
      [200, { 'Content-Type' => 'text/plain' }, [''] ]
    end
  end

  let(:json_content_type) { 'application/json' }  
  let(:env)               { Hash.new  }
  let(:logger)            { double('Logger', debug: true)}
  let(:upstream_status)   { 200 }
  let(:upstream_headers)  { { 'Content-Type' => 'text/plain' } }
  let(:upstream_body)     { { key: 'value' } }
  let(:events_route)      { { organization: 'organization', topic: 'topic', type: 'events' } }
  let(:event_route)       { { organization: 'organization', topic: 'topic', type: 'event' } }
  let(:stash_route)       { { organization: 'organization', topic: 'topic', type: 'stash' } }
  let(:stashes_route)     { { organization: 'organization', type: 'stashes' } }
end
