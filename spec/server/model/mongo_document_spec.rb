require 'spec_helper'

describe Vayacondios::MongoDocument do

  describe "constructing BSON::ObjectIds from" do
    let(:string) { 'aaaaaaaaaaaaaaaaaaaaaaaa' }
    let(:bson)   { BSON::ObjectID(string)     }
    context "Hash with '$oid' key" do
      subject { MongoDocument.format_id({'$oid' => string}) }
      it      { should == bson }
    end
    context "a string that could be a BSON::ObjectId" do
      subject { MongoDocument.format_id(string) }
      it      { should == bson }
    end
    context "a string that couldn't be a BSON::ObjectId" do
      subject { MongoDocument.format_id('hello there') }
      it      { should == 'hellothere' }
    end
  end
  
end
