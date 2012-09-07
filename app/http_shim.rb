#!/usr/bin/env ruby

require 'vayacondios-server'
require 'multi_json'

class HttpShim < Goliath::API
  use Goliath::Rack::Tracer, 'X-Tracer' # log trace statistics
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::Heartbeat          # respond to /status with 200, OK (monitoring, etc)

  def response(env)
    # Validate path_params
    path_params = parse_path(env[Goliath::Request::REQUEST_PATH])
    return [400, {}, MultiJson.dump({error: "Bad Request"})] if !path_params.present? || method_name(env).nil?

    # TODO refactor a middlware
    # Decode the document body
    body = nil
    begin
      if env['rack.input']
        body = env['rack.input'].read
        body = MultiJson.decode(body) if !body.blank?
        env['rack.input'].rewind
      end
    rescue MultiJson::DecodeError => ex
      return [400, {}, MultiJson.dump({error: "Bad Request"})]
    end
    # Look up handler using inflection
    klass = ('vayacondios/' + path_params[:type] + '_handler').camelize.constantize

    begin
      case method_name(env)

      when :show
        record = klass.find(mongo, path_params)
        [200, {}, MultiJson.dump(record.body)]

      when :update
        record = klass.new(mongo).update(body, path_params)
        [200, {}, nil]
        
      when :patch
        record = klass.new(mongo).patch(body, path_params)
        [200, {}, nil]

      when :delete
        record = klass.find(mongo, path_params).destroy(body)
        [200, {}, MultiJson.dump(record.body)]
      
      when :create
        return [405, ({'Allow' => "GET PUT PATCH DELETE"}), nil]
      end
    rescue Vayacondios::Error::NotFound => ex
      return [404, {}, MultiJson.dump({error: "Not Found"})]
    rescue Vayacondios::Error::BadRequest => ex
      return [400, {}, MultiJson.dump({error: "Bad Request"})]
    rescue Exception => ex
      puts ex
      ex.backtrace.each{|l| puts l}
    end
  end

  private

  # Determine the organization, type of action (config or event), the topic,
  # id, and format for the request.
  def parse_path path
    path_regex = /^\/v1\/(?<organization>[a-z]\w+)\/(?<type>config|event|itemset)(\/(?<topic>\w+)(\/(?<id>(\w+\/?)+))?)?(\/|\.(?<format>json))?$/i
    if (match = path_regex.match(path))
      {}.tap do |segments|
        match.names.each do |segment|
          segments[segment.to_sym] = match[segment]
        end
      end
    end
  end

  def method_name env
    case env['REQUEST_METHOD'].upcase
    when "GET"
      :show
    when "PUT"
      if env['HTTP_X_METHOD'] && env['HTTP_X_METHOD'].upcase == 'PATCH'
        :patch
      else
        :update
      end
    when "POST"
      :create
    when "PATCH"
      :patch
    when "DELETE"
      :delete
    end
  end
end