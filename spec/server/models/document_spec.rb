require 'spec_helper'

describe Vayacondios::Server::Document do
  
  let(:params){ { organization: 'organization', topic: 'topic' } }

  subject(:document){ described_class.new(log, database, params) }

end
