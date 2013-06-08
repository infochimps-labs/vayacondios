shared_context "events", events: true do
  let(:nil_event)   { nil               } ; let(:json_nil_event)   { 'null'          }
  let(:hash_event)  { {'foo' =>  'bar'} } ; let(:json_hash_event)  { '{"foo":"bar"}' }
  let(:array_event)  { [1,2,3]          } ; let(:json_array_event)  { '[1,2,3]'       }
  let(:string_event) { "HELLO"          } ; let(:json_string_event) { '"HELLO"'       }
  let(:numeric_event){ 1                } ; let(:json_numeric_event){ '1'             }
  
  let(:event_query)                        { {'foo' => 'bar'} }
  let(:event_query_with_sort)              { {'foo' => 'bar', 'sort'  => ['bing', 'descending']} }
  let(:event_query_with_limit)             { {'foo' => 'bar', 'limit' => 10 } }
  let(:event_query_with_fields)            { {'foo' => 'bar', 'fields' => %w[bing bam] } }
  let(:event_query_with_string_time)       { {'foo' => 'bar', 'time' => {"gte" => "2013-06-08 01:19:15 -0500"}} }
  let(:event_query_with_int_time)          { {'foo' => 'bar', 'time' => {"gte" => 1370672418 } } }
end
  
shared_context "stashes", stashes: true do
  let(:nil_stash)    { nil              } ; let(:json_nil_stash)    { 'null'          }
  let(:hash_stash)   { {'foo' => 'bar'} } ; let(:json_hash_stash)   { '{"foo":"bar"}' }
  let(:array_stash)  { [1,2,3]          } ; let(:json_array_stash)  { '[1,2,3]'       }
  let(:string_stash) { "HELLO"          } ; let(:json_string_stash) { '"HELLO"'       }
  let(:numeric_stash){ 1                } ; let(:json_numeric_stash){ '1'             }

  let(:stash_query)            { {'foo' => 'bar'} }
  let(:stash_query_with_limit) { {'foo' => 'bar', 'limit' => 10} }
  let(:stash_query_with_sort)  { {'foo' => 'bar', 'sort'  => ['bar', 'ascending']} }
end
