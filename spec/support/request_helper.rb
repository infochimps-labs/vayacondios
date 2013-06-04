def vcd options={}, &block
  with_api(Vayacondios::HttpServer, config: File.join(VCD_ROOT, 'config/vcd-server.rb'), environment: 'test') do |api|
    
    request = {path: options[:path]}.tap do |req|
      req[:body] = MultiJson.dump(options[:body]) if options[:body]
    end
    
    callback = Proc.new{ |client| fail "HTTP Options Failed #{client.response_header.status} -- }#{client.options}" }
    
    send("#{options[:verb].to_s.downcase}_request", request, callback) do |client|
      client.instance_eval(&block) if block_given?
      
      client.response_header.status.should   == options[:status]   if options[:status]

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
    end
    EM.stop
  end
end
