# All examples assume a running Vayacondios server on localhost:3467
# with a backing database.
#
# bundle exec ruby examples/event_stream.rb
require 'vayacondios/client'

client = Vcd::Client::HttpClient.new(organization: 'github')

client.stream('commit') do |event|
  line = "#{event['time']} | #{event['username']}: #{event['sha']} => #{event['message']}"
  puts line
end

# In another window:
# curl -X POST 'http://localhost:3467/v3/github/event/commit' -d '{"username":"Jack","sha":"123abc","message":"watup"}'
# curl -X POST 'http://localhost:3467/v3/github/event/commit' -d '{"username":"Jill","sha":"abc123","message":"yoyo"}'
#
# To remove the event topic:
# curl -X DELETE 'http://localhost:3467/v3/github/events/commit'
