# The Document model is a base model used by Event, Stash, &c.
#
# The `organization` and `topic` properties are defined as instance
# attributes because they are used for routing the document.
# Subclasses should continue to store each separate piece of routing
# information as its own instance variable and store the entire
# payload/data as a single field.
#
#   organization             coca_cola
#   |---- topic              |---- ad_campaigns
#   |---- ...     ------>    |---- web_traffic
#   `---- topic              `---- social_media_buzz
#
# @attr [String] organization the organization this document belongs to
# @attr [String] topic the unit which identifies documents of a given "kind"
module Vayacondios::Server
  class Document
    include Gorillib::Model

    field :organization, String
    field :topic,        String
    field :id,           String
    field :body,         Hash
    field :filter,       Hash

    def receive_organization name
      @organization = sanitize_location_name(name).gsub(/^system\./, '_system.')
    end

    def format_response result
      from_document(result.symbolize_keys.compact).external_document
    end
  
    # A class for errors that arise within documents due to internal or
    # IO errors.
    Error = Class.new(StandardError)

    # Sanitize a string to make a suitable component of a database
    # location name.
    #
    # Replaces all characters that aren't letters, digits, underscores,
    # periods, or hyphens with underscores.  Also replaces periods at
    # the beginning or at the end of a collection name with an
    # underscore.
    #
    # @param [String] name
    # @return [String] the sanitized `name`
    def sanitize_location_name name
      name.to_s.gsub(/^\.|[^-\w\.]+|\.$/, '_')
    end

    class << self
      def extract_query_options! params
        params.symbolize_keys!
        opts = {}
        [:limit, :order, :sort, :fields].each{ |opt| opts[opt] = params.delete opt }
        opts.merge default_query_options
      end

      def search(params, query, &driver)
        options = extract_query_options! query
        action  = receive(params).prepare_search(query)
        result  = driver.call(action, action.filter, options)
        result.map{ |res| new.format_response res }
      end
      
      def create(params, document, &driver)
        action = receive(params).prepare_create(document)
        result = driver.call(action)
        action.format_response result
      end

      def find(params, &driver)
        action = receive(params).prepare_find
        result = driver.call(action, {})
        return nil if result.nil?
        action.format_response result
      end
      
      def destroy(params, document, &driver)
        action = receive(params).prepare_destroy(document.symbolize_keys)
        result = driver.call(action, action.filter)
        return result
      end
    end
  end
end
