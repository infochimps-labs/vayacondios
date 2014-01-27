require 'spec_helper'

describe Vayacondios::Server::MongoDriver do
  include LogHelper

  let!(:settings){ Vayacondios::Server::DbConfig.env :test }

  subject{ described_class.connect settings.merge(log: log) }
  
  def using(location, &blk)
    EM.synchrony do
      driver.set_location location
      blk.call(subject)
      EM.stop
    end
  end

  context '#insert' do
    it 'returns the id' do
      using('organization.foo.event') do |driver| 
        driver.insert(foo: bar)
      end
    end
  end

  

end
