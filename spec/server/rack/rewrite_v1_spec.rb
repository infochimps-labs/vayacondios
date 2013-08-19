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

    context "from v1 clients, if they are fetch requests," do
      let (:v1_patch_req) {
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
        upstream_items.should_receive(:call)
          .with(v1_patch_req.merge({
                            'REQUEST_PATH' => '/v2/testorg/stash/testtopic/testid',
                          }))
          .and_return([200,
                       {'Content-Type' => 'application/json'},
                       ['{"hashfoo": "foo", "hashbar": "bar", "hashbaz": ""}']])
        expect(described_class.new(upstream_items).call(v1_patch_req)).
          to eq([200, {'Content-Type' => 'application/json'}, '["foo","bar"]'])
      end
    end

    context "from v1 clients, if they are create requests," do
      let (:v1_patch_req) {
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
        upstream_items.should_receive(:call)
          .with(v1_patch_req.merge({
                            'REQUEST_METHOD' => 'POST',
                            'REQUEST_PATH' => '/v2/testorg/stash/testtopic/testid',
                          }))
          .and_return([200,
                       {'Content-Type' => 'application/json'},
                       ['{"hashfoo": "foo", "hashbar": "bar", "hashbaz": ""}']])
        expect(described_class.new(upstream_items).call(v1_patch_req)).
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
          [200,
           {'Content-Type' => 'application/json'},
           ['{"hashfoo": "foo", "hashbar": "bar", "hashbaz": ""}']]
        end
      }
      it "translates them to PUT requests" do
        upstream_items.should_receive(:call)
          .with(v1_patch_req.merge({
                            'REQUEST_METHOD' => 'PUT',
                            'REQUEST_PATH' => '/v2/testorg/stash/testtopic/testid',
                          }))
          .and_return([200,
                       {'Content-Type' => 'application/json'},
                       ['{"hashfoo": "foo", "hashbar": "bar", "hashbaz": ""}']])
        expect(described_class.new(upstream_items).call(v1_patch_req)).
          to eq([200, {'Content-Type' => 'application/json'}, ''])
      end
    end

    context "from v1 clients, if they are remove requests," do
      let (:v1_patch_req) {
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
        upstream_items.should_receive(:call)
          .with(v1_patch_req.merge({
                            'REQUEST_METHOD' => 'PUT',
                            'REQUEST_PATH' => '/v2/testorg/stash/testtopic/testid',
                          }))
          .and_return([200,
                       {'Content-Type' => 'application/json'},
                       ['{"hashfoo": "", "hashbar": "", "hashbaz": ""}']])
        expect(described_class.new(upstream_items).call(v1_patch_req)).
          to eq([200, {'Content-Type' => 'application/json'}, '[]'])
      end
    end
  end

  describe "handling errors" do
    context "it converts error messages for 404s" do
      let (:v1_patch_req) {
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
        upstream_items.should_receive(:call)
          .with(v1_patch_req.merge({
                            'REQUEST_METHOD' => 'GET',
                            'REQUEST_PATH' => '/v2/testorg/stash/testtopic/testid',
                          }))
          .and_return([404,
                       {'Content-Type' => 'application/json'},
                       ['["Stash with topic <a> and ID <b> not found"]']])
        expect(described_class.new(upstream_items).call(v1_patch_req)).
          to eq([404, {'Content-Type' => 'application/json'}, '{"error":"Not Found"}'])
      end
    end

    context "it converts error messages for 404s" do
      let (:v1_patch_req) {
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
        upstream_items.should_receive(:call)
          .with(v1_patch_req.merge({
                            'REQUEST_METHOD' => 'GET',
                            'REQUEST_PATH' => '/v2/testorg/stash/testtopic/testid',
                          }))
          .and_return([404,
                       {'Content-Type' => 'application/json'},
                       ['["Stash with topic <a> and ID <b> not found"]']])
        expect(described_class.new(upstream_items).call(v1_patch_req)).
          to eq([404, {'Content-Type' => 'application/json'}, '{"error":"Not Found"}'])
      end
    end
  end
end
