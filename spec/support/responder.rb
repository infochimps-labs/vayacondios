#!/usr/bin/env ruby
require 'goliath'

# run standalone as:
# ruby -r ./lib/boot.rb ./spec/support/responder.rb -sv -p 9003 -e prod

class Responder < Goliath::API
  use Goliath::Rack::Params

  def on_headers(env, headers)
    env['client-headers'] = headers
  end

  def response(env)
    query_params  = env.params.collect{|param| param.join(": ") }
    query_headers = env['client-headers'].collect{|param| param.join(": ") }
    params_str = query_params.join("|").gsub(/[\r\n]+/, "")[0...200]

    headers = {"Special" => "Header",
      "Params"  => params_str,
      "Path"    => env[Goliath::Request::REQUEST_PATH],
      "Headers" => query_headers.join("|"),
      "Method"  => env[Goliath::Request::REQUEST_METHOD]}
    [200, headers, "Hello from Responder: #{params_str}"]
  end
end
