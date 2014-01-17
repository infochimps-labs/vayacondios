require 'spec_helper'

describe Vayacondios::Server::Api do
  include Goliath::TestHelper

  TestResponse = Struct.new(:status, :body, :headers) do
    def parsed_body
      MultiJson.load body
    end
  end

  def build_request(verb, path, params = {})
    options = { path: path }
    options[:headers] = params[:headers] if params[:headers]
    options[:body]    = params[:body]    if params[:body]
    proc{ |&callback| send("#{verb}_request", options, &callback) }
  end

  let(:captured_assertions){ [] }

  def perform(request, &blk)
    response = nil
    with_api(described_class) do |server|
      yield server.api if block_given?
      request.call do |client| 
        response = TestResponse.new(client.response_header.status.to_i, client.response, client.response_header)
      end
      captured_assertions.each{ |a| raise a if a.is_a?(Exception) }
    end
    response
  end

  def capture_assertions(&code)
    code.call
  rescue RSpec::Expectations::ExpectationNotMetError => e
    captured_assertions << e    
  end
  
  def stub_response(api, result = nil, &blk)
    api.stub(:response) do |env|
      capture_assertions do
        blk.call(api, env)
      end
      result || success_response   
    end
  end

  def success_response
    [200, {}, {}]
  end
  
  def stub_handler(api, result = {}, &blk)
    handler = double(:handle, call: result)
    handler_class = double(:handler_class, new: handler)
    api.stub(:handler).and_return handler_class
    if block_given?
      handler.should_receive(:call) do |action, routes, document|
        capture_assertions{ blk.call(action, routes, document) }
        result
      end
    end
  end
  
  context 'Rack', 'Heartbeat' do
    subject(:response){ perform build_request(:get, '/status') }
    
    it 'returns a heartbeat message' do
      response.body.should eq('OK')
    end
  end

  context 'Rack', 'ApiVersion' do
    subject(:response){ perform build_request(:get, '/version') }

    it 'returns the server api version' do
      response.body.should eq(Vayacondios::VERSION)
    end

    it 'attaches a version header to every response' do
      response = perform build_request(:get, '/v2/org/event/topic')
      response.headers['X_VAYACONDIOS_VERSION'].should eq(Vayacondios::VERSION)
    end
  end

  context 'Rack', 'ForceContentType' do
    let(:request) { build_request(:post, '/v2/org/event/topic', body: '{"foo":"bar"}') }
    let(:response){ perform request }

    it 'accepts a JSON body with no header' do
      perform(request) do |server|
        stub_handler(server, {}) do |action, routes, document|
          document.should eq('foo' => 'bar')
        end
      end
    end

    it 'attaches a JSON content header to every response' do
      response.headers['CONTENT_TYPE'].should match('application/json')
    end
  end

  context 'Rack', 'Formatters::JSON' do
    subject(:response) do
      perform build_request(:get, '/v2/org/event/topic') do |server|
        stub_handler(server, { foo: 'bar' })
      end
    end

    it 'serializes all response bodies as JSON' do
      response.parsed_body.should eq('foo' => 'bar')
    end
  end

  context 'Rack', 'Params' do
    it 'provides parsed params to the response method' do
      request = build_request(:post, '/v2/org/event/topic', body: '{"foo":"bar"}')
      perform(request) do |server|
        stub_response(server, success_response) do |api|
          api.should respond_to(:document)
          api.document.should eq('foo' => 'bar')
        end
      end
    end

    it 'handles non-Hash JSON values' do
      request = build_request(:post, '/v2/org/event/topic', body: '["foo","bar"]')
      perform(request) do |server|
        stub_response(server, success_response) do |api|
          api.document.should eq(%w[ foo bar ])
        end
      end      
    end
  end

  context 'Rack', 'Validation::RequestMethod' do
    %w[ HEAD OPTIONS ].each do |method|
      it "returns a validation error on #{method} requests" do
        response = perform build_request(method.downcase.to_sym, '/v2/org/event/topic')
        response.status.should eq(405)
      end
    end
  end

  context 'Rack', 'ControlMethods' do
    {
      post:   :create,
      get:    :retrieve,
      patch:  :update,
      patch:  :update,
      delete: :delete,
    }.each_pair do |http_verb, handler_action|
      it "maps #{http_verb.to_s.upcase} verbs to handler method #{handler_action}" do
        perform build_request(http_verb, '/v2/org/event/topic') do |server|
          stub_handler(server) do |action, routes, document|
            action.should eq(handler_action)
          end
        end
      end
    end
  end

  context 'Rack', 'Validation::Routes' do
    it 'returns a validation error when the route is not valid' do
      response = perform build_request(:get, '/invalid/route/fool')
      response.status.should eq(400)
      response.parsed_body['error'].should match('/v2/<organization>/<type>/<topic>/<id>')
    end

    it 'parses the route pieces' do
      perform build_request(:get, '/v2/twitter/event/hashtag/emoji') do |server|
        stub_response(server) do |api|
          api.should respond_to(:routes)
          api.routes.should eq(organization: 'twitter', 
                               type:         'event',
                               topic:        'hashtag',
                               id:           'emoji')
        end
      end
    end
  end

  context 'Rack', 'Validation::RouteHandler' do
    {
      event:   Vayacondios::Server::EventHandler,
      events:  Vayacondios::Server::EventsHandler,
      stash:   Vayacondios::Server::StashHandler,
      stashes: Vayacondios::Server::StashesHandler,
    }.each_pair do |type, handler|
      it "maps type #{type} to handler #{handler}" do
        request = build_request(:get, "/v2/infochimps/#{type}/topic")
        perform(request) do |server|
          stub_response(server, success_response) do |api|
            api.handler.should be(handler)
          end
        end
      end
    end

    it 'returns a validation error when a handler cannot be found' do
      response = perform build_request(:get, '/v2/infochimps/invalid/topic')
      response.status.should eq(400)
      response.parsed_body['error'].should match('No handler found')
    end
  end

  context 'Rack', 'Validation::RequiredRoutes' do
    it 'returns a validation error when a stash does not have a topic' do
      response = perform build_request(:get, '/v2/infochimps/stash')
      response.status.should eq(400)
      response.parsed_body['error'].should match('A topic route is required')
    end

    it 'returns a validation error when an event does not have a topic' do
      response = perform build_request(:get, '/v2/infochimps/event')
      response.status.should eq(400)
      response.parsed_body['error'].should match('A topic route is required')
    end

    it 'returns a validation error when events do not have a topic' do
      response = perform build_request(:get, '/v2/infochimps/events')
      response.status.should eq(400)
      response.parsed_body['error'].should match('A topic route is required')
    end
  end

  context 'Rack', '#response' do
    let(:request){ build_request(:get, '/v2/infochimps/event/topic') }

    it 'returns a validation error when a handler raises one' do
      response = perform(request) do |server|
        stub_handler(server) do |action, routes, document|
          raise Goliath::Validation::NotFoundError.new("Dude, where's my car?")
        end
      end
      response.status.should eq(404)
      response.parsed_body['error'].should eq("Dude, where's my car?")
    end

    it 'returns a document error when a handler raises one' do
      response = perform(request) do |server|
        stub_handler(server) do |action, routes, document|
          raise Vayacondios::Server::Document::Error.new('Invalid')
        end
      end
      response.status.should eq(400)
      response.parsed_body['error'].should eq('Invalid')
    end

    it 'returns a server error when a handler raises one' do
      response = perform(request) do |server|
        stub_handler(server) do |action, routes, document|
          raise ZeroDivisionError.new('infinity')
        end
      end
      response.status.should eq(500)
      response.parsed_body['error'].should match('ZeroDivisionError')
    end

    it 'returns a successful response on success' do
      response = perform(request) do |server|
        stub_handler(server, { foo: 'bar' })
      end
      response.status.should eq(200)
      response.parsed_body.should eq('foo' => 'bar')
    end
  end
end
