# All examples assume a running Vayacondios server on localhost:3467
# with a backing database.
#
# bundle exec ruby examples/simple.rb
require 'vayacondios/client'

# Basic client usage
client = Vcd::Client::HttpClient.new(organization: 'github')

# Events
client.announce('commit', username: 'Jack', sha: '123abc', message: 'watup')
puts client.events('commit').body.inspect
puts client.clear_events('commit').body.inspect

# Stashes
client.set(123, nil, user_name: 'jimbob', user_id: 123, group: 'admin')
puts client.get(123).body

# Mixin Vcd functionality
class SimpleModel
  extend  Vcd::Client::HttpRead
  include Vcd::Client::HttpWrite
  include Vcd::Client::HttpAdmin

  # Must respond to organization for requests to be formed correctly
  # default is 'vayacondios'
  def self.organization() 'github' ; end

  def self.find topic
    data = get(topic).body
    self.new data
  end
  
  attr_accessor :user_name, :user_id, :group

  def initialize(data = {})
    @user_name = data['user_name']
    @user_id   = data['user_id']
    @group     = data['group']
  end

  def organization
    self.class.organization
  end

  def to_hash
    { user_name: user_name, user_id: user_id, group: group }
  end

  def save
    set(user_id, nil, to_hash)
  end

  def destroy!
    unset(user_id)
  end
end

model = SimpleModel.find('123')
puts model.to_hash
model.destroy!
