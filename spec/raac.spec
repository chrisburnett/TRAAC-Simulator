require_relative '../raac'
require_relative '../requester'
require_relative '../parameters'
require 'spec_helper'


RSpec.describe Raac do

  FactoryGirl.find_definitions

  describe "authorisation function" do

    before(:each) do
      @model = Raac.new
      @requester = build(:requester)
      @recipient = build(:requester)

      # default test request
      @request = {
        requester: @requester,
        recipient: @recipient
      }

      # default test group assignments
      @groups = {
        @requester => [ :g1 ],
        @recipient => [ :g2 ]

      }

    end

    context "when the requester is not in the share zone" do

      it "denies the request if the requester is in the read zone" do
        ind_policy = { @requester.id => :read }
        result = @model.new_authorisation_decision(@request, ind_policy, {}, @groups)
        expect(result).to be false
      end
      it "denies the request if the requester is in the deny zone" do
        ind_policy = { @requester.id => :deny }
        result = @model.new_authorisation_decision(@request, ind_policy, {}, @groups)
        expect(result).to be false
      end
      it "denies the request if the requester is in the undefined zone" do
        ind_policy = { @requester.id => :undefined }
        result = @model.new_authorisation_decision(@request, ind_policy, {}, @groups)
        expect(result).to be false
      end
      
    end


    context "when the requester is in the share zone" do

      it "denies the request if the recipient is in the deny zone" do
        ind_policy = { @requester.id => :share, @recipient.id => :deny  }
        result = @model.new_authorisation_decision(@request, ind_policy, {}, @groups)
        expect(result).to be false
      end

      it "allows the request if the recipient is in the read zone" do
        ind_policy = { @requester.id => :share, @recipient.id => :read  }
        result = @model.new_authorisation_decision(@request, ind_policy, {}, @groups)
        expect(result).to be true
      end
      
      it "allows the request if the recipient is in the share zone" do
        ind_policy = { @requester.id => :share, @recipient.id => :share  }
        result = @model.new_authorisation_decision(@request, ind_policy, {}, @groups)
        expect(result).to be true
      end
    end



    
    context "when the requester is in the undefined zone" do
        
      it "allows if the requester is in a share-zone group, and the recipient can read" do
        ind_policy = { @requester.id => :undefined, @recipient.id => :read }
        grp_policy = { :g1 => :share }
        result = @model.new_authorisation_decision(@request, ind_policy, grp_policy, @groups)
        expect(result).to be true
      end

      it "denies if the requester is in a share-zone group, and the recipient cannot read" do
        ind_policy = { @requester.id => :undefined, @recipient.id => :deny }
        grp_policy = { :g1 => :share }
        result = @model.new_authorisation_decision(@request, ind_policy, grp_policy, @groups)
        expect(result).to be false
      end
    

    end


    context "when the requester and recipient are both in the undefined zone" do
      
      it "allows if the requester is in a share-zone group, and the recipient is in a group which can read" do
        ind_policy = { @requester.id => :undefined, @recipient.id => :undefined }
        grp_policy = { :g1 => :share, :g2 => :read }
        result = @model.new_authorisation_decision(@request, ind_policy, grp_policy, @groups)
        expect(result).to be true
      end
    end
   

  end
end
