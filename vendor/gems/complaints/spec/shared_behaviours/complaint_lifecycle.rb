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

  describe "depiction of close_memo prompt when editing a closed complaint" do
    context "when complaint close_memo is other_reason" do
      before do
        closed_status = ComplaintStatus.where(name: "Closed").first
        complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, close_memo: "some other reason"}] 
        complaint.save
        visit complaint_path('en', complaint.id)
        edit_complaint
      end

      it "should show the close_memo value in the button" do
        expect(page.find('#close_memo_prompt').text).to eq "some other reason"
        click_button('some other reason')
        expect(page.find('#other').value).to eq "some other reason"
      end
    end

    context "when complaint close_memo is referred_to" do
      before do
        closed_status = ComplaintStatus.where(name: "Closed").first
        complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, close_memo: "Referred to: another agency"}] 
        complaint.save
        visit complaint_path('en', complaint.id)
        edit_complaint
      end

      it "should show the close_memo value in the button" do
        expect(page.find('#close_memo_prompt').text).to eq "Referred to: another agency"
        click_button('Referred to: another agency')
        expect(page.find('#referred').value).to eq "another agency"
      end
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
      expect(StatusChange.most_recent_first.first.close_memo).to be_blank
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
      expect(page.find('#close_memo_prompt').text).to eq "No jurisdiction"
      choose('Assessment')
      check('(Information pending)')
      choose('Closed')
      expect(page.find('#close_memo_prompt').text).to eq "No jurisdiction"
      choose('Investigation')
      choose('Closed')
      expect(page.find('#close_memo_prompt').text).to eq "No jurisdiction"
    end
  end

  describe "change from closed to investigation status and save... close_memo not submitted" do
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

  describe "when a status has assessment memo" do
    before do
      assessment_status = ComplaintStatus.where(name: "Assessment").first
      complaint.status_changes_attributes = [{complaint_status_id: assessment_status.id, close_memo: "(Information pending)"}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should indicate the presence of the assessment memo" do
      expect(page.find('input#assessment_memo')).to be_checked
      choose('Closed')
      expect(page.find('#close_memo_prompt').text).to eq "Close memo"
      choose('Assessment')
      check('assessment_memo')
      choose('Closed')
      expect(page.find('#close_memo_prompt').text).to eq "Close memo"
    end
  end

  describe 'assign assessment status' do
    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, close_memo: "No jurisdiction"}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should show assessment memo" do
      expect(page.find('input#closed')).to be_checked
      expect(page.find('#close_memo_prompt').text).to eq "No jurisdiction"
      choose('Assessment')
      check('assessment_memo')
      edit_save
      expect(complaint.reload.current_status.complaint_status.name).to eq "Assessment"
      expect(complaint.reload.current_status.close_memo).to eq "(Information pending)"
      expect(page.all('#status_changes .status_change .status_humanized').first.text).to eq "Assessment, (Information pending)"
      edit_complaint
      expect(page.find('input#assessment')).to be_checked
      expect(page.find('input#assessment_memo')).to be_checked
    end
  end

  describe 'transfer case during assessment' do
    it "shows case transfer within status timeline" do
      expect(page.all('select#transferees option.office').count).to eq Office.count
      select(Office.first, :from => "transferees")
    end
  end
end
