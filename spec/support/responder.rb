# run standalone as:
# ruby -r ./lib/boot.rb ./spec/support/responder.rb -sv -p 9003 --config $PWD/config/app.rb -e prod &

class Responder < Goliath::API
  use Goliath::Rack::Params

  def on_headers(env, headers)
    env['client-headers'] = headers
  end

  def response(env)
    query_params = env.params.collect { |param| param.join(": ") }
    query_headers = env['client-headers'].collect { |param| param.join(": ") }

    headers = {"Special" => "Header",
      "Params" => query_params.join("|"),
      "Path" => env[Goliath::Request::REQUEST_PATH],
      "Headers" => query_headers.join("|"),
      "Method" => env[Goliath::Request::REQUEST_METHOD]}
    [200, headers, "Hello from Responder"]
  end
end
