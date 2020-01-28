require 'rails_helper'
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'complaints_spec_helpers'
require 'area_subarea_common_helpers'

feature "complaint register", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers
  include AreaSubareaCommonHelpers

  before do
    populate_database(:individual_complaint)
    visit complaint_intake_path('en', 'individual')
  end

  it "initiates registration via duplicate complaints check" do
    page.find("#proceed_to_intake").click
    expect(page_heading).to eq "Individual Complaint Intake"
    complete_required_fields(:individual)
    expect{save_complaint}.to change{ IndividualComplaint.count }.by(1)
    expect(IndividualComplaint.last.current_status_humanized).to eq "Registered"
  end
end

feature "assessment status next step", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_agencies
    create_complaint_statuses
    populate_areas_subareas
    complaint = FactoryBot.create( :individual_complaint, :with_associations, :assessment, assigned_to: @user, date_received: Date.today.advance(years: -2, days: -1))
    visit complaint_path('en', complaint.id)
    edit_complaint
  end

  describe "close memo warnings" do
    it "should show warnings until preset reason is selected" do
      choose('closed')
      edit_save
      expect(page).to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      click_button('Close memo')
      page.find('li#preset', text: 'No jurisdiction').click
      expect(page).not_to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end

    it "should show warnings until referree is entered" do
      choose('closed')
      edit_save
      expect(page).to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      click_button('Close memo')
      fill_in('referred', with: 'another agency')
      expect(page).not_to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end

    it "should show warnings until other reason is entered" do
      choose('closed')
      edit_save
      expect(page).to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      click_button('Close memo')
      fill_in('other', with: 'another reason')
      expect(page).not_to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end

    it "should show warnings until other status is selected" do
      choose('closed')
      edit_save
      expect(page).to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      choose("Investigation")
      expect(page).not_to have_selector('#close_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end
  end

  describe "apply closed status, select preset close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    it "should show warnings until preset reason is selected" do
      choose('closed')
      click_button('Close memo')
      page.find('li#preset', text: 'No jurisdiction').click
      expect{edit_save; wait_for_ajax}.to change{StatusChange.count}.by 1
      expect(StatusChange.last.complaint_status_id).to eq closed_status.id
      expect(StatusChange.last.close_memo).to eq "No jurisdiction"
    end
  end

  describe "apply closed status, enter 'other' close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    it "should show warnings until preset reason is selected" do
      choose('closed')
      click_button('Close memo')
      fill_in('other', with: "some other reason")
      expect{edit_save; wait_for_ajax}.to change{StatusChange.count}.by 1
      expect(StatusChange.last.complaint_status_id).to eq closed_status.id
      expect(StatusChange.last.close_memo).to eq "some other reason"
    end
  end

  describe "apply closed status, enter 'referred to' close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    it "should show warnings until preset reason is selected" do
      choose('closed')
      click_button('Close memo')
      fill_in('referred', with: "another agency")
      expect{edit_save; wait_for_ajax}.to change{StatusChange.count}.by 1
      expect(StatusChange.last.complaint_status_id).to eq closed_status.id
      expect(StatusChange.last.close_memo).to eq "Referred to: another agency"
    end
  end

  describe "apply investigation status" do
    let(:investigation_status){ ComplaintStatus.where(name: "Investigation").first }
    it "should show warnings until preset reason is selected" do
      choose('investigation')
      expect{edit_save; wait_for_ajax}.to change{StatusChange.count}.by 1
      expect(StatusChange.last.complaint_status_id).to eq investigation_status.id
      expect(StatusChange.last.close_memo).to be_nil
    end
  end
end
