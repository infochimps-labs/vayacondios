require 'spec_helper'

describe Vayacondios::Rack::RewriteV1, rack: true do

  subject { described_class.new(upstream)   }

  describe "processing requests" do
    context "from v2 clients" do
      let (:v2_patch_req) {
        env.merge({
                    'REQUEST_METHOD' => 'PUT',
                    'REQUEST_PATH' => '/v2/testorg/stash/testtopic/testid',
                    'HTTP_X_METHOD' => 'PATCH',
                    'rack.input' => StringIO.new('{"foo" => "bar"}')
                  })
      }
      it "passes them on unmodified" do
        upstream.should_receive(:call)
          .with(v2_patch_req)
          .and_return([200, kind_of(Hash), ['']])
        subject.call(v2_patch_req)
      end
    end

    context "from other clients" do
      let (:empty_req) {
        env.merge({
                    'REQUEST_METHOD' => 'GET',
                    'REQUEST_PATH' => '/',
                    'rack.input' => StringIO.new('')
                  })
      }
      it "passes them on unmodified" do
        upstream.should_receive(:call)
          .with(empty_req)
          .and_return([200, {}, ['']])
        subject.call(empty_req).should == [200, {}, ['']]
      end
    end

    context "from v1 clients, if they are fetch requests," do
      let (:v1_get_req) {
        env.merge({
                    'REQUEST_METHOD' => 'GET',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new(''),
                    'async.callback' => kind_of(Proc)
                  })
      }
      let (:upstream_items) {
        Proc.new do |env|
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashbar": "bar", "hashbaz": ""}']]
        end
      }
      it "translates them to GET requests" do
        upstream_items.should_receive(:call) do |req|
          req['REQUEST_METHOD'].should == 'GET'
          req['REQUEST_PATH'].should == '/v2/testorg/stash/testtopic/testid'
          req['rack.input'].read.should == ''
          req['HTTP_X_METHOD'].should == nil
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashbar": "bar", "hashbaz": ""}']]
        end
        expect(described_class.new(upstream_items).call(v1_get_req)).
          to eq([200, {'Content-Type' => 'application/json'}, '["foo","bar"]'])
      end
    end

    context "from v1 clients, if they are create requests," do
      let (:v1_create_req) {
        env.merge({
                    'REQUEST_METHOD' => 'PUT',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new('["foo", "bar"]'),
                    'async.callback' => kind_of(Proc)
                  })
      }
      let (:upstream_items) {
        Proc.new do |env|
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashbar": "bar", "hashbaz": ""}']]
        end
      }
      it "translates them to POST requests" do
        upstream_items.should_receive(:call) do |req|
          req['REQUEST_METHOD'].should == 'POST'
          req['REQUEST_PATH'].should == '/v2/testorg/stash/testtopic/testid'
          MultiJson.load(req['rack.input'].read).values.sort.should == %w[foo bar].sort
          req['HTTP_X_METHOD'].should == nil
          [200, {'Content-Type' => 'application/json'}, ['']]
        end
        expect(described_class.new(upstream_items).call(v1_create_req)).
          to eq([200, {'Content-Type' => 'application/json'}, ''])
      end
    end

    context "from v1 clients, if they are patch requests," do
      let (:v1_patch_req) {
        env.merge({
                    'REQUEST_METHOD' => 'PUT',
                    'HTTP_X_METHOD' => 'PATCH',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new('["foo", "bar"]'),
                    'async.callback' => kind_of(Proc)
                  })
      }
      let (:upstream_items) {
        Proc.new do |env|
          [200, {'Content-Type' => 'application/json'}, ['']]
        end
      }
      it "translates them to PUT requests" do
        upstream_items.should_receive(:call) do |req|
          req['REQUEST_METHOD'].should == 'PUT'
          req['REQUEST_PATH'].should == '/v2/testorg/stash/testtopic/testid'
          MultiJson.load(req['rack.input'].read).values.sort.should == %w[foo bar].sort
          req['HTTP_X_METHOD'].should == nil

          [200, {'Content-Type' => 'application/json'}, ['']]
        end
        expect(described_class.new(upstream_items).call(v1_patch_req)).
               to eq([200, {'Content-Type' => 'application/json'}, ''])
      end
    end

    context "from v1 clients, if they are remove requests," do
      let (:v1_delete_req) {
        env.merge({
                    'REQUEST_METHOD' => 'DELETE',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new('["foo", "bar"]'),
                    'async.callback' => kind_of(Proc)
                  })
      }
      let (:upstream_items) {
        Proc.new do |env|
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "", "hashbar": "", "hashbaz": ""}']]
        end
      }
      it "translates them to PUT requests" do
        upstream_items.should_receive(:call) do |req|
          req['REQUEST_METHOD'].should == 'PUT'
          req['REQUEST_PATH'].should == '/v2/testorg/stash/testtopic/testid'
          MultiJson.load(req['rack.input'].read).sort.should == {
            Vayacondios::Rack::RewriteV1.hash_item('foo') => '',
            Vayacondios::Rack::RewriteV1.hash_item('bar') => '',
          }.sort
          req['HTTP_X_METHOD'].should == nil
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "", "hashbar": "", "hashbaz": ""}']]
        end
        expect(described_class.new(upstream_items).call(v1_delete_req)).
          to eq([200, {'Content-Type' => 'application/json'}, '[]'])
      end
    end
  end

  describe "handling errors" do
    context "it converts error messages for 404s" do
      let (:v1_get_req) {
        env.merge({
                    'REQUEST_METHOD' => 'GET',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new(''),
                    'async.callback' => kind_of(Proc)
                  })
      }
      let (:upstream_items) {
        Proc.new do |env|
          [404,
           {'Content-Type' => 'application/json'},
           ['["Stash with topic <a> and ID <b> not found"]']]
        end
      }
      it "and makes them consistent with v1" do
        upstream_items.should_receive(:call) do |req|
          req['REQUEST_METHOD'].should == 'GET'
          req['REQUEST_PATH'].should == '/v2/testorg/stash/testtopic/testid'
          req['rack.input'].read.should == ''
          req['HTTP_X_METHOD'].should == nil
          [404,
           {'Content-Type' => 'application/json'},
           ['["Stash with topic <a> and ID <b> not found"]']]
        end
        expect(described_class.new(upstream_items).call(v1_get_req)).
          to eq([404, {'Content-Type' => 'application/json'}, '{"error":"Not Found"}'])
      end
    end

    context "when there is no topic" do
      let (:v1_get_req) {
        env.merge({
                    'REQUEST_METHOD' => 'PUT',
                    'REQUEST_PATH' => '/v1/testorg/itemset',
                    'rack.input' => StringIO.new(''),
                    'async.callback' => kind_of(Proc)
                  })
      }
      it "raises an error" do
        expect{subject.call(v1_get_req)}.to raise_error(Goliath::Validation::Error, /bad request/i)
      end
    end

    context "when proessing a POST request" do
      let (:v1_get_req) {
        env.merge({
                    'REQUEST_METHOD' => 'POST',
                    'REQUEST_PATH' => '/v1/testorg/itemset',
                    'rack.input' => StringIO.new(''),
                    'async.callback' => kind_of(Proc)
                  })
      }
      it "raises an error" do
        expect{subject.call(v1_get_req)}.to raise_error(Goliath::Validation::Error,
                                                        /invalid request method/i)
      end
    end

    context "when proessing a hash instead of an array" do
      let (:v1_get_req) {
        env.merge({
                    'REQUEST_METHOD' => 'PUT',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new('{"foo":"bar"}'),
                    'async.callback' => kind_of(Proc)
                  })
      }
      it "raises an error" do
        expect{subject.call(v1_get_req)}.to raise_error(Goliath::Validation::Error, /bad request/i)
      end
    end

    context "when creating mixed item types" do
      let (:v1_mixed_create_req) {
        env.merge({
                    'REQUEST_METHOD' => 'PUT',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new('["foo", 1]'),
                    'async.callback' => kind_of(Proc)
                  })
      }
      let (:upstream_items) {
        Proc.new do |env|
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashone": 1, "hashbaz": ""}']]
        end
      }
      it "translates them appropriately to POST requests" do
        upstream_items.should_receive(:call) do |req|
          req['REQUEST_METHOD'].should == 'POST'
          req['REQUEST_PATH'].should == '/v2/testorg/stash/testtopic/testid'
          MultiJson.decode(req['rack.input'].read).values.should == ["foo", 1]
          req['HTTP_X_METHOD'].should == nil
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashone": 1, "hashbaz": ""}']]
        end
        expect(described_class.new(upstream_items).call(v1_mixed_create_req)).
          to eq([200, {'Content-Type' => 'application/json'}, ''])
      end
    end

    context "when fetching mixed item types" do
      let (:v1_mixed_create_req) {
        env.merge({
                    'REQUEST_METHOD' => 'GET',
                    'REQUEST_PATH' => '/v1/testorg/itemset/testtopic/testid',
                    'rack.input' => StringIO.new(''),
                    'async.callback' => kind_of(Proc)
                  })
      }
      let (:upstream_items) {
        Proc.new do |env|
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashone": 1, "hashbaz": ""}']]
        end
      }
      it "translates them appropriately to GET requests" do
        upstream_items.should_receive(:call) do |req|
          req['REQUEST_METHOD'].should == 'GET'
          req['REQUEST_PATH'].should == '/v2/testorg/stash/testtopic/testid'
          req['rack.input'].read.should == ''
          req['HTTP_X_METHOD'].should == nil
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashone": 1, "hashbaz": ""}']]
        end
        expect(described_class.new(upstream_items).call(v1_mixed_create_req)).
          to eq([200, {'Content-Type' => 'application/json'}, '["foo",1]'])
      end
    end
  end
end
