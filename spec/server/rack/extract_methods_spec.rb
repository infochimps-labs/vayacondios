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
  
  context 'PUT' do    
    context 'without http_x_method' do
      it 'correctly extracts :update' do
        env.merge!('REQUEST_METHOD' => 'PUT')
        subject.extract_method(env).should == :update      
      end
    end
    
    context 'with http_x_method' do
      it 'correctly extracts :patch' do
        env.merge!('REQUEST_METHOD' => 'PUT', 'HTTP_X_METHOD' => 'PATCH')
        subject.extract_method(env).should == :patch
      end      
    end
  end

  context 'GET' do
    it 'correctly extracts :show' do
      env.merge!('REQUEST_METHOD' => 'GET')
      subject.extract_method(env).should == :show
    end    
  end

  context 'POST' do
    it 'correctly extracts :create' do
      env.merge!('REQUEST_METHOD' => 'POST')
      subject.extract_method(env).should == :create
    end

  end

  context 'PATCH' do
    it 'correctly extracts :patch' do
      env.merge!('REQUEST_METHOD' => 'PATCH')
      subject.extract_method(env).should == :patch
    end
  end

  context 'DELETE' do
    it 'correctly extracts :delete' do
      env.merge!('REQUEST_METHOD' => 'DELETE')
      subject.extract_method(env).should == :delete
    end
  end  
end
