require 'rails_helper'
require_relative '../../../authengine/spec/helpers/user_setup_helper'

describe "scope class methods" do
  include UserSetupHelper

  describe "query by current assignee" do
    before do
      @user = create_user('admin')
      @staff_user = create_user('staff')
      FactoryBot.create(:complaint, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :assigned_to => [@staff_user, @user])
    end

    it "returns complaints based on assignee" do
      expect(Complaint.for_assignee(@user.id)).to eq Complaint.all.select{|c| c.current_assignee_id == @user.id}
      expect(Complaint.for_assignee(@staff_user.id)).to eq Complaint.all.select{|c| c.current_assignee_id == @staff_user.id}
      expect(Complaint.for_assignee.pluck(:id)).to match_array Complaint.pluck(:id)
    end
  end

  describe "query by current status" do
    before do
      FactoryBot.create(:complaint, :open)
      FactoryBot.create(:complaint, :closed)
      FactoryBot.create(:complaint, :under_evaluation)
    end

    it "returns complaints with current requested status" do
      expect(Complaint.with_status(:open)).to eq Complaint.all.select{|c| c.current_status == 'Open'}
      expect(Complaint.with_status(:closed)).to eq Complaint.all.select{|c| c.current_status == 'Closed'}
      expect(Complaint.with_status(:under_evaluation)).to eq Complaint.all.select{|c| c.current_status == 'Under Evaluation'}
    end
  end

  describe "query by current status and current assignee" do
    before do
      @user = create_user('admin')
      @staff_user = create_user('staff')
      FactoryBot.create(:complaint, :open, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :closed, :assigned_to => [@user, @staff_user])
      FactoryBot.create(:complaint, :open, :assigned_to => [@staff_user, @user])
      FactoryBot.create(:complaint, :closed, :assigned_to => [@staff_user, @user])
    end

    it "should merge the two scopes" do
      expect(Complaint.with_status(:open).for_assignee(@user.id).length).to eq 1
    end
  end

  describe "a test that should not fail" do
    before do
      FactoryBot.create(:complaint, :open)
    end

    it "should merge the two scopes" do
      expect(Complaint.first.current_status) == "Open"
      expect(Complaint.with_status(:open).length).to eq 1
    end
  end
end
