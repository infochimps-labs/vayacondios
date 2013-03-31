class Vayacondios::Document < Hash
  attr_accessor :organization, :topic

  # The Document model is a base model used by EventDocument,
  # ConfigDocument, &c..  It defines two namespacing properties:
  #
  #   * `organization` - the top level unit under which all data is stored
  #   * `topic` - the unit which identifies stuff of a "given kind"
  #
  def initialize(options = {})
    @options          = sanitize_options(options)
    self.organization = options[:organization]
    self.topic        = options[:topic]
  end

  def sanitize_options options
    options.symbolize_keys
  end

  def self.find
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end

  def self.create
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end

  def self.update
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end

  def self.destroy
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end
end
