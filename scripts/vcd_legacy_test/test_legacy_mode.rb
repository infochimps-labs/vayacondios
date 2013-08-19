require 'httparty'
require 'multi_json'

host = 'localhost'
port = '9000'
org = 'testorg'
id = 'testid'
topic = 'testtopic'

# want to test GET/PUT/PATCH

def uri_str(host, port, org, id, topic)
  "http://#{host}:#{port}/v1/#{org}/itemset/#{topic}/#{id}"
end

def get uri_str_val
  HTTParty.get(uri_str_val)
end

def put uri_str_val, items, headers = {}
  HTTParty.put(uri_str_val, 
               body: MultiJson.encode(items),
               headers: {
                 'Content-Type' => 'application/json',
               }.merge(headers))
end

def remove uri_str_val, items
  HTTParty.delete(uri_str_val, 
               body: MultiJson.encode(items),
               headers: {
                 'Content-Type' => 'application/json',
               })
end

def create uri_str_val, items
  put(uri_str_val, items)
end

def update uri_str_val, items
  put(uri_str_val, items, 'X-Method' => 'Patch')
end

def error msg
  raise Exception.new(msg)
end

itemset = uri_str(host, port, org, id, topic)
noexist_itemset = uri_str(host, port, org, 'hsaxbz', topic)

def assert_equals(expected, actual)
  unless expected == actual
    STDERR.puts("expected #{expected.inspect} but received #{actual.inspect}")
  end
end

STDERR.puts("running tests. no news is good news.", "-"*80)

assert_equals("", create(itemset, ["foo"]).response.body)
assert_equals("[\"foo\"]", get(itemset).response.body)
assert_equals("", update(itemset, ["bar"]).response.body)
assert_equals("[\"foo\",\"bar\"]", get(itemset).response.body)
assert_equals("[\"foo\"]", remove(itemset, ["bar"]).response.body)
assert_equals("{\"error\":\"Not Found\"}", get(noexist_itemset).response.body)

STDERR.puts("-"*80,"tests complete.")
