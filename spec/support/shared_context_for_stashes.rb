shared_context 'stashes', stashes: true do
  let(:nil_stash)               { nil }
  let(:json_nil_stash)          { 'null' }
  let(:hash_stash)              { { 'foo' => 'bar' } }
  let(:json_hash_stash)         { '{"foo":"bar"}' }
  let(:array_stash)             { [1, 2, 3] }
  let(:json_array_stash)        { '[1,2,3]' }
  let(:string_stash)            { 'HELLO' }
  let(:json_string_stash)       { '"HELLO"' }
  let(:numeric_stash)           { 1 }
  let(:json_numeric_stash)      { '1' }
  let(:nested_stash)            { { 'root' => { 'b' => 2, 'c' => { 'x' => 3 }, 'a' => 1 } } }
  let(:stash_query)             { { 'foo' => 'bar' } }
  let(:json_stash_query)        { MultiJson.dump(stash_query) }
  let(:nested_stash_query)      { { 'root.b' => 2 } }
  let(:json_nested_stash_query) { MultiJson.dump(nested_stash_query) }
  let(:stash_query_with_limit)  { { 'foo' => 'bar', 'limit' => 10 } }
  let(:stash_query_with_sort)   { { 'foo' => 'bar', 'sort'  => %w[ bar ascending ] } }
  let(:stash_query_with_topic)  { { 'foo' => 'bar', 'topic' => 'baz' } }
  let(:stash_replacement)       { { 'foo' => 'baz' } }
  let(:json_stash_replacement)  { '{"foo":"baz"}' }
  let(:stash_update)            { { 'counter' => 1 } }
  let(:json_stash_update)       { '{"counter":1}' }
end
