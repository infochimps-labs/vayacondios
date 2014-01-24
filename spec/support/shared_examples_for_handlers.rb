shared_examples 'handlers', behaves_like: 'handler' do
  include LogHelper

  let!(:driver) do
    db = Class.new{ include Vayacondios::Server::Driver }.new
    db.set_log log
    db
  end

  def validation_error
    Goliath::Validation::Error
  end

  def success_response
    handler.action_successful
  end

  subject(:handler){ described_class.new(log, driver) }

  it{ should respond_to(:log) }
  it{ should respond_to(:database) }

  its(:action_successful){ should eq(ok: true) }
  
  context '#call' do
    it 'calls base methods for logging before delegating' do
      handler.log.should_receive(:debug).at_least(1).times
      handler.should_receive(:create).with({}, {})
      handler.call(:create, {}, {})
    end
  end
end
