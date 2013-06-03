require 'spec_helper'
require_relative '../../lib/vayacondios/legacy_switch'

require 'multi_json'

require_relative '../../lib/vayacondios/client/itemset'

describe Vayacondios::Client::ItemSet do
  context "after instantiation in legacy mode" do
    itemset = Vayacondios::Client::ItemSet.new("foohost", 9999, "fooorg", "footopic", "fooid")
    ary = ["foo", "bar", "baz"]

    # testing internals here to avoid shimming up HTTP libraries.

    it "generates a put request without a patch header when asked to create" do
      Vayacondios.force_legacy_mode true

      req = itemset.instance_eval{_req(:create, ary)}

      req.method.should eql('PUT')
      req.body.should eql(MultiJson.encode(ary))
      req.path.should eql('/v1/fooorg/itemset/footopic/fooid')
      req.each_header.to_a.should_not include(["x_method", "PATCH"])
    end

    it "generates a put request with a patch header when asked to update" do
      Vayacondios.force_legacy_mode true

      req = itemset.instance_eval{_req(:update, ary)}

      req.method.should eql('PUT')
      req.body.should eql(MultiJson.encode(ary))
      req.path.should eql('/v1/fooorg/itemset/footopic/fooid')
      req.each_header.to_a.should include(["x-method", "PATCH"])
    end

    it "generates a get request when asked to fetch" do
      req = itemset.instance_eval{_req(:fetch)}

      req.method.should eql('GET')
      req.body.should be_nil
      req.path.should eql('/v1/fooorg/itemset/footopic/fooid')
    end

    it "generates a delete request when asked to remove" do
      Vayacondios.force_legacy_mode true

      req = itemset.instance_eval{_req(:remove, ary)}

      req.method.should eql('DELETE')
      req.body.should eql(MultiJson.encode(ary))
      req.path.should eql('/v1/fooorg/itemset/footopic/fooid')
    end
  end
end
