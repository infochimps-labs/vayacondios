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

    # A class for errors that arise within documents due to internal or
    # IO errors.
    Error = Class.new(StandardError)
    
    attr_accessor :organization, :topic

    # Create a new document.
    #
    # @param [Hash] params
    # @option params [String] organization the name of this document's organization
    # @option params [String] topic the name of this document's topic
    def initialize(params={})
      @params           = sanitize_params(params)
      self.organization = (@params[:organization] or raise Error.new("Must provide an :organization when instantiating a #{self.class}"))
      self.topic        = @params[:topic]
    end

    # Find a particular document.
    def self.find *args
      raise NotImplementedError.new("#{self}.find must be overriden by a subclass.")
    end

    # Search for documents.
    def self.search *args
      raise NotImplementedError.new("#{self}.search must be overriden by a subclass.")
    end
    
    # Create a document.
    def self.create *args
      raise NotImplementedError.new("#{self}.create must be overriden by a subclass.")
    end

    # Update a document.
    def self.update *args
      raise NotImplementedError.new("#{self}.update must be overriden by a subclass.")
    end

    # Destroy a document.
    def self.destroy *args
      raise NotImplementedError.new("#{self}.destroy must be overriden by a subclass.")
    end

    private

    # :nodoc:
    def sanitize_params params
      params.symbolize_keys
    end
    
  end
end
