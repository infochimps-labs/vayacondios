shared_context 'events', events: true do
  let(:nil_event)                    { nil }
  let(:json_nil_event)               { 'null' }
  let(:hash_event)                   { { 'foo' => 'bar'} }
  let(:json_hash_event)              { '{"foo":"bar"}' }
  let(:array_event)                  { [1, 2, 3] }
  let(:json_array_event)             { '[1,2,3]' }
  let(:string_event)                 { 'HELLO' }
  let(:json_string_event)            { '"HELLO"' }
  let(:numeric_event)                { 1 }
  let(:json_numeric_event)           { '1' }
  let(:nested_event)                 { { 'A' => 1, 'B' => { 'c' => 2, 'd' => 3 } } }
  let(:json_nested_event)            { MultiJson.dump(nested_event) }  
  let(:event_query)                  { { 'foo' => 'bar' } }
  let(:json_event_query)             { MultiJson.dump(event_query) }  
  let(:event_query_with_sort)        { { 'foo' => 'bar', 'sort' => %w[ bing descending ] } }
  let(:event_query_with_limit)       { { 'foo' => 'bar', 'limit' => 10 } }
  let(:event_query_with_fields)      { { 'foo' => 'bar', 'fields' => %w[ bing bam ] } }
  let(:event_query_with_string_time) { { 'foo' => 'bar', 'from' => '2013-06-08 01:19:15 -0500' } }
  let(:event_query_with_int_time)    { { 'foo' => 'bar', 'from' => 1370672418 } }
  let(:event_query_with_id)          { { 'foo' => 'bar', 'id' => 'baz' } }
end
