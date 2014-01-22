require_relative '../../spec/support/database_helper'
require_relative '../../spec/support/log_helper'
require 'em-synchrony/em-http'

include DatabaseHelper
include LogHelper

def make_request(verb, path, body = nil)
  EM::Synchrony.sleep(0.1) # Make sure the db call is complete
  params = { path: path }
  params[:body] = MultiJson.dump(body) if body
  EM::HttpRequest.new('http://localhost:9000').send(verb.to_s.downcase, params)
end

def stash_location()      'organization.stash'           ; end
def event_location(topic) "organization.#{topic}.events" ; end

Before do
  db_reset!
end

Given(/^there are no matching Stashes in the database$/) do
  database_count(stash_location).should == 0
end

Given(/^the following Stash exists in the database:$/) do |json|
  insert_record(stash_location, MultiJson.load(json))
end

Given(/^there are no Events under topic "(.*?)" in the database$/) do |topic|
  database_count(event_location topic).should == 0
end

Given(/^the following Event exists under topic "(.*?)" in the database:$/) do |topic, json|
  event = MultiJson.load json
  event['_t'] = Time.parse(event['_t']).round(3).utc if event.has_key?('_t')
  insert_record(event_location(topic), event)
end

When(/^the client sends a (GET|POST|PUT|DELETE) request to "(.*?)" with no body$/) do |verb, path|
  @response = make_request(verb, path)
end

When(/^the client sends a (GET|POST|PUT|DELETE) request to "(.*?)" with the following body:$/) do |verb, path, json|
  @response = make_request(verb, path, MultiJson.load(json))
end

When(/^the client open a stream request to "(.*?)" with the following body:$/) do |path, json|
  @queue = []
  @response = make_request('GET', path, MultiJson.load(json))
  @response.stream{ |chunk| @queue << chunk }
end

Then(/^the response status should be (\d+)$/) do |status|
  @response.response_header.status.to_s.should == status
end

Then(/^the response body should be:$/) do |json|
  MultiJson.load(@response.response).should == MultiJson.load(json)
end

Then(/^the response body should contain:$/) do |json|
  MultiJson.load(@response.response).should include(MultiJson.load json)
end

Then(/^the response body should contain a randomly assigned Id$/) do
  body = MultiJson.load @response.response
  body.should have_key('id')
  body['id'].should be_a(String)
  body['id'].size.should_not be_zero
end

Then(/^the response body should contain a generated timestamp$/) do
  body = MultiJson.load @response.response
  body.should have_key('time')
  body['time'].should be_a(String)
  Time.parse(body['time']).should be_within(1).of(Time.now)
end

Then(/^the stream response body should be:$/) do |json|
  MultiJson.load(@queue.shift).should eq(MultiJson.load json)
end

Then(/^the database should have the following Stash:$/) do |json|
  retrieve_record(stash_location).should == MultiJson.load(json)
end

Then(/^there are no Stashes in the database$/) do
  database_count('organization.stash').should == 0
end

Then(/^there is exactly one Event under topic "(.*?)" in the database$/) do |topic|
  database_count(event_location topic).should == 1
end

Then(/^the database should have the following Event under topic "(.*?)":$/) do |topic, json|
  db_event = retrieve_record(event_location topic)
  db_event["_t"] = db_event["_t"].iso8601(3)
  db_event.should == MultiJson.load(json)
end

Then(/^there (should|should not) be an Event with Id "(.*?)" under topic "(.*?)" in the database$/) do |assert, id, topic|
  result = retrieve_record(event_location(topic), { _id: id })
  if assert =~ /not/
    result.should be_nil
  else
    result.should_not be_nil
  end
end

After do
  db_reset!
end
