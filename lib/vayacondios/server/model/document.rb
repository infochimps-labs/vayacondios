class Vayacondios::Document < Hash
  attr_accessor :organization, :topic

  def initialize(options = {})
    options = options.symbolize_keys
    @organization = options[:organization]
    @topic = options[:topic]
  end

  def self.create
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end

  def self.update
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end

  def self.find
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end

  def destroy
    raise NotImplementedError.new("#{self.name} must be overriden by a subclass.")
  end
end