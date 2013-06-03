# The Document model is a base model used by Event, Stash, &c.  It
# defines two namespacing properties:
#
#   * `organization` - the top level unit under which all data is stored
#   * `topic` - the unit which identifies stuff of a "given kind"
class Vayacondios::Document

  Error = Class.new(StandardError)
  
  attr_accessor :organization, :topic

  def initialize(params={})
    @params           = sanitize_params(params)
    self.organization = (@params[:organization] or raise Error.new("Must provide an :organization when instantiating a #{self.class}"))
    self.topic        = (@params[:topic]        or raise Error.new("Must provide a topic when instantiating a #{self.class}"))
  end
  
  def sanitize_params params
    params.symbolize_keys
  end

  def self.find *args
    raise NotImplementedError.new("#{self}.find must be overriden by a subclass.")
  end

  def self.create *args
    raise NotImplementedError.new("#{self}.create must be overriden by a subclass.")
  end

  def self.update *args
    raise NotImplementedError.new("#{self}.update must be overriden by a subclass.")
  end

  def self.patch *args
    raise NotImplementedError.new("#{self}.patch must be overriden by a subclass.")
  end
  
  def self.destroy *args
    raise NotImplementedError.new("#{self}.destroy must be overriden by a subclass.")
  end
end
