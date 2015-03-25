require_relative '../raac'

RSpec.describe Raac do

  describe "authorisation function" do

    context "when evaluating read requests from users for which a policy is defined" do
      it "allows a read request from a user in the read zone"
      it "allows a read request from a user in the share zone"
      it "rejects a read request from a user in the deny zone"
    end

    context "when evaluating share requests from users for which a policy is defined" do
      it "denies a share request from a user in the read zone"
      it "allows a share request from a user in the share zone"
      it "denies a share request from a user in the deny zone"
    end




  end
end
