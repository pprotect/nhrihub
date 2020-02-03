require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'complaints_spec_helpers'

RSpec.shared_examples  "complaint lifecycle" do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_agencies
    create_complaint_statuses
    populate_areas_subareas
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
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq closed_status.id
      expect(StatusChange.most_recent_first.first.close_memo).to eq "No jurisdiction"
      expect(all('#complaint #status_changes .status_change .status_humanized').map(&:text)).to eq ['Closed, No jurisdiction','Assessment','Registered']
    end
  end

  describe "apply closed status, enter 'other' close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    it "should show warnings until preset reason is selected" do
      choose('closed')
      click_button('Close memo')
      fill_in('other', with: "some other reason")
      expect{edit_save; wait_for_ajax}.to change{StatusChange.count}.by 1
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq closed_status.id
      expect(StatusChange.most_recent_first.first.close_memo).to eq "some other reason"
      expect(all('#complaint #status_changes .status_change .status_humanized').map(&:text)).to eq ['Closed, some other reason','Assessment','Registered']
    end
  end

  describe "apply closed status, enter 'referred to' close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    it "should show warnings until preset reason is selected" do
      choose('closed')
      click_button('Close memo')
      fill_in('referred', with: "another agency")
      expect{edit_save; wait_for_ajax}.to change{StatusChange.count}.by 1
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq closed_status.id
      expect(StatusChange.most_recent_first.first.close_memo).to eq "Referred to: another agency"
      expect(all('#complaint #status_changes .status_change .status_humanized').map(&:text)).to eq ['Closed, Referred to: another agency','Assessment','Registered']
    end
  end

  describe "apply investigation status" do
    let(:investigation_status){ ComplaintStatus.where(name: "Investigation").first }
    it "should show warnings until preset reason is selected" do
      choose('investigation')
      expect{edit_save; wait_for_ajax}.to change{StatusChange.count}.by 1
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq investigation_status.id
      expect(StatusChange.most_recent_first.first.close_memo).to be_nil
    end
  end

  describe "persistence of original attribute" do
    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, close_memo: "No jurisdiction"}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should persist the original close_memo attribute when selecting another status and returning to closed" do
      choose('Assessment')
      choose('Closed')
      expect(page.find('#close_memo_prompt').text).to eq "No jurisdiction"
    end
  end

  describe "change from closed status and save... close_memo not submitted" do
    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, close_memo: "No jurisdiction"}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should zeroize close_memo before saving" do
      choose('Investigation')
      edit_save
      expect(complaint.reload.current_status.close_memo).to be_blank
      expect(complaint.reload.current_status.complaint_status.name).to eq "Investigation"
    end
  end
end
