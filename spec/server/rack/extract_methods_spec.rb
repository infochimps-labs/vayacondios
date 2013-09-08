require 'spec_helper'
require 'vayacondios/server/rack/extract_methods'

describe Vayacondios::Rack::ExtractMethods do
  let(:env){ { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded; charset=utf-8' } }
  let(:app){ mock('app').as_null_object }
  subject  { described_class.new(app)   }
    
  it 'adds a key in env for :vayacondios_method' do
    app.should_receive(:call).with do |app_env|
      app_env.keys.should include(:vayacondios_method)
    end
    subject.call(env)
  end

  context "for a single /event" do
    before { env.merge!(:vayacondios_route => { :type => 'event' }) }
    it "routes a GET request to the :show action" do
      env.merge!("REQUEST_METHOD" => "GET")
      subject.extract_method(env).should == :show
    end
    it "routes a POST request to the :create action" do
      env.merge!("REQUEST_METHOD" => "POST")
      subject.extract_method(env).should == :create
    end
    it "doesn't route a PUT request" do
      env.merge!("REQUEST_METHOD" => "PUT")
      expect { subject.extract_method(env) }.to raise_error(Goliath::Validation::Error, /PUT.*event/)
    end
    it "doesn't route a PATCH request" do
      env.merge!("HTTP_X_METHOD" => "PATCH")
      expect {subject.extract_method(env) }.to raise_error(Goliath::Validation::Error, /PUT.*event/)
    end
    it "doesn't route a DELETE request" do
      env.merge!("REQUEST_METHOD" => "DELETE")
      expect { subject.extract_method(env) }.to raise_error(Goliath::Validation::Error, /DELETE.*event/)
    end
  end

  context "for multiple /events" do
    before { env.merge!(:vayacondios_route => { :type => 'events' }) }
    it "routes a GET request to the :search action" do
      env.merge!("REQUEST_METHOD" => "GET")
      subject.extract_method(env).should == :search
    end
    it "doesn't route a POST request" do
      env.merge!("REQUEST_METHOD" => "POST")
      expect { subject.extract_method(env) }.to raise_error(Goliath::Validation::Error, /POST.*event/)
    end
    it "doesn't route a PUT request" do
      env.merge!("REQUEST_METHOD" => "PUT")
      expect { subject.extract_method(env) }.to raise_error(Goliath::Validation::Error, /PUT.*event/)
    end
    it "doesn't route a PATCH request" do
      env.merge!("HTTP_X_METHOD" => "PATCH")
      expect {subject.extract_method(env) }.to raise_error(Goliath::Validation::Error, /PUT.*event/)
    end
    it "doesn't route a DELETE request" do
      env.merge!("REQUEST_METHOD" => "DELETE")
      expect { subject.extract_method(env) }.to raise_error(Goliath::Validation::Error, /DELETE.*event/)
    end
  end

  context "for a single /stash" do
    before { env.merge!(:vayacondios_route => { :type => 'stash' }) }
    it "routes a GET request to the :show action" do
      env.merge!("REQUEST_METHOD" => "GET")
      subject.extract_method(env).should == :show
    end
    it "routes a POST request to the :create action" do
      env.merge!("REQUEST_METHOD" => "POST")
      subject.extract_method(env).should == :create
    end
    it "routes a PUT request to the :update action" do
      env.merge!("REQUEST_METHOD" => "PUT")
      subject.extract_method(env).should == :update
    end
    it "routes a PATCH request to the :update action" do
      env.merge!("HTTP_X_METHOD" => "PATCH")
      subject.extract_method(env).should == :update
    end
    it "routes a DELETE request to the :destroy action" do
      env.merge!("REQUEST_METHOD" => "DELETE")
      subject.extract_method(env).should == :delete
    end
  end

  context "for multiple /stashes" do
    before { env.merge!(:vayacondios_route => { :type => 'stashes' }) }
    it "routes a GET request to the :search action" do
      env.merge!("REQUEST_METHOD" => "GET")
      subject.extract_method(env).should == :search
    end
    it "routes a POST request to the :replace_many action" do
      env.merge!("REQUEST_METHOD" => "POST")
      subject.extract_method(env).should == :replace_many
    end
    it "routes a PUT request to the :update_many action" do
      env.merge!("REQUEST_METHOD" => "PUT")
      subject.extract_method(env).should == :update_many
    end
    it "routes a PATCH request to the :update_many action" do
      env.merge!("HTTP_X_METHOD" => "PATCH")
      subject.extract_method(env).should == :update_many
    end
    it "routes a DELETE request to the :delete_many action" do
      env.merge!("REQUEST_METHOD" => "DELETE")
      subject.extract_method(env).should == :delete_many
    end
  end
  
end
