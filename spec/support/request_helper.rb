# This is a helper method that encapsulates a simple functional test.
# During each invocation of `vcd`
#
# 1. A new Vayacondios::Server::Api is booted up
#   a. Using the `config/vcd-server.rb` file distributed with the Vayacondios source
#   b. in the `test` environment
# 2. You can specify the given HTTP verb, path, and body of a new HTTP request
# 3. You can specify the expected status code along with somewhat complex properties of the body in the resulting HTTP response
#
# @param [Hash] options the options of the test
# @option options [String] verb the given HTTP verb (GET, PUT, POST, DELETE) for the request
# @option options [String] path the given path for the request
# @option options [String] body the given body for the request
# @option options [Integer] status the expected HTTP response code (200, 404, &c.) of the response
# @option options [String, Regexp] matches a regular expression which should match the response body
# @option options [Array<String>, String] includes argument to be passed to RSpec's `include` matcher
# @option options [String, Numeric, Hash, Array] equals the parsed response body should equal this Ruby object
# @option options [String] error a regular expression which matches the error message returned in the response body
module RequestHelper
  def vcd(options = {}, &blk)
    with_api(Vayacondios::Server::Api, config: File.join(VCD_ROOT, 'config/vcd-server.rb'), environment: 'test') do |api|
      
      request = {path: options[:path]}.tap do |req|
        req[:body] = MultiJson.dump(options[:body]) if options[:body]
      end
      
      callback = Proc.new{ |client| fail "HTTP Options Failed #{client.response_header.status}" }
      
      send("#{options[:verb].to_s.downcase}_request", request, callback) do |client|
        begin
          client.instance_eval(&blk) if block_given?
          
          client.response_header.status.should == options[:status] if options[:status]
          
          client.response.should match(options[:matches]) if options[:matches]
          
          response = MultiJson.load(client.response) if options[:includes] || options[:error] || options[:equals]
          
          response.should == options[:equals] if options.include?(:equals)
          
          if options.include?(:includes)
            if options[:includes].is_a?(Array)
              response.should include(*options[:includes])
            else
              response.should include(options[:includes])
            end
          end
          
          response['error'].should match(options[:error]) if options[:error]
        rescue => e
          stop
          raise e
        end
      end

    end
  end
end
