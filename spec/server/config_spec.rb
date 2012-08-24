require 'spec_helper'

require 'multi_json'

require File.join(File.dirname(__FILE__), '../../', 'app/http_shim')

describe HttpShim do
  include Goliath::TestHelper

  let(:err) { Proc.new{ |c| fail "HTTP Request Failed #{c.response}" } }

  context 'Configuration management' do
    it 'stores configuration' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/config/power/level',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql ({
            "topic" => "power",
            "status" => "success",
            "cargo" => {
              "level" => "awesome"
            }
          })
        end
      end
    end

    it 'retrieves configuration' do
      with_api(HttpShim) do |api|
        post_request({
          :path => '/v1/infochimps/config/power/level',
          :body => {:level=>"awesome"}
        }, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql ({
            "topic" => "power",
            "status" => "success",
            "cargo" => {
              "level" => "awesome"
            }
          })
        end
      end
      with_api(HttpShim) do |api|
        get_request({:path => '/v1/infochimps/config/power/level'}, err) do |c|
          c.response_header.status.should == 200
          MultiJson.load(c.response).should eql({
            "topic" => "power",
            "status" => "success",
            "cargo" => {
              "level" => "awesome"
            }
          })
        end
      end
    end
  end
end