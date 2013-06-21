shared_context "events", events: true do
  let(:nil_event)   { nil               } ; let(:json_nil_event)   { 'null'          }
  let(:hash_event)  { {'foo' =>  'bar'} } ; let(:json_hash_event)  { '{"foo":"bar"}' }
  let(:array_event)  { [1,2,3]          } ; let(:json_array_event)  { '[1,2,3]'       }
  let(:string_event) { "HELLO"          } ; let(:json_string_event) { '"HELLO"'       }
  let(:numeric_event){ 1                } ; let(:json_numeric_event){ '1'             }
  
  let(:event_query)                        { {'foo' => 'bar'} }
  let(:json_event_query)                   { MultiJson.dump(event_query) }
  
  let(:event_query_with_sort)              { {'foo' => 'bar', 'sort'  => ['bing', 'descending']} }
  let(:event_query_with_limit)             { {'foo' => 'bar', 'limit' => 10 } }
  let(:event_query_with_fields)            { {'foo' => 'bar', 'fields' => %w[bing bam] } }
  let(:event_query_with_string_time)       { {'foo' => 'bar', "from" => "2013-06-08 01:19:15 -0500"} }
  let(:event_query_with_int_time)          { {'foo' => 'bar', "from" => 1370672418 } }
  let(:event_query_with_id)                { {'foo' => 'bar', 'id' => 'baz' } }
end

shared_context "stashes", stashes: true do
  let(:nil_stash)    { nil              } ; let(:json_nil_stash)    { 'null'          }
  let(:hash_stash)   { {'foo' => 'bar'} } ; let(:json_hash_stash)   { '{"foo":"bar"}' }
  let(:array_stash)  { [1,2,3]          } ; let(:json_array_stash)  { '[1,2,3]'       }
  let(:string_stash) { "HELLO"          } ; let(:json_string_stash) { '"HELLO"'       }
  let(:numeric_stash){ 1                } ; let(:json_numeric_stash){ '1'             }

  let(:stash_query)            { {'foo' => 'bar'} }
  let(:json_stash_query)       { MultiJson.dump(stash_query) }
  
  let(:stash_query_with_limit) { {'foo' => 'bar', 'limit' => 10} }
  let(:stash_query_with_sort)  { {'foo' => 'bar', 'sort'  => ['bar', 'ascending']} }
  let(:stash_query_with_topic) { {'foo' => 'bar', 'topic' => 'baz' } }
end

shared_context "rack", rack: true do
  
  let(:upstream) do
    Proc.new do |env|
      [200, {'Content-Type' => 'text/plain'}, [''] ]
    end
  end

  let(:json_content_type) { 'application/json' }
  
  let(:env)     { Hash.new  }
  let(:logger)  { mock("Logger", debug: true)}
  before        { env.stub!(:logger).and_return(logger) }

  let(:upstream_status)  { 200 }
  let(:upstream_headers) { { "Content-Type" => "text/plain" } }
  let(:upstream_body)    { { key: "value" } }

  let(:events_route)           { {organization: 'organization', topic: 'topic', type: 'events' } }
  let(:event_route)            { {organization: 'organization', topic: 'topic', type: 'event' } }
  let(:stash_route)            { {organization: 'organization', topic: 'topic', type: 'stash' } }
  let(:stashes_route)          { {organization: 'organization', type: 'stashes' } }

end
