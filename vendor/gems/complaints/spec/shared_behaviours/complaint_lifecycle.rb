require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'complaints_spec_helpers'

RSpec.shared_examples  "complaint lifecycle" do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_offices
    create_agencies
    create_complaint_statuses
    populate_areas_subareas
    visit complaint_path('en', complaint.id)
    edit_complaint
  end

  describe "close memo warnings" do
    it "should show warnings until preset reason is selected" do
      # starts with status: assessment memo: Information pending
      choose('closed')
      edit_save
      expect(page).to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      click_button('Close memo')
      page.find('li#preset', text: 'No jurisdiction').click
      expect(page).not_to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end

    it "should show warnings until referree is entered" do
      choose('closed')
      edit_save
      expect(page).to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      click_button('Close memo')
      fill_in('referred', with: 'another agency')
      expect(page).not_to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end

    it "should show warnings until other reason is entered" do
      choose('closed')
      edit_save
      expect(page).to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      click_button('Close memo')
      fill_in('other', with: 'another reason')
      expect(page).not_to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end

    it "should show warnings until other status is selected" do
      choose('closed')
      edit_save
      expect(page).to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
      choose("Investigation")
      expect(page).not_to have_selector('#status_memo_error', :text => "You must supply a reason for closing")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end
  end

  describe "depiction of status_memo prompt when editing a closed complaint" do
    context "when complaint status_memo is other_reason" do
      before do
        closed_status = ComplaintStatus.where(name: "Closed").first
        complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, status_memo: "some other reason", status_memo_type: :close_other_reason}] 
        complaint.save
        visit complaint_path('en', complaint.id)
        edit_complaint
      end

      it "should show the status_memo value in the button" do
        expect(page.find('#status_memo_prompt').text).to eq "some other reason"
        click_button('some other reason')
        expect(page.find('#other').value).to eq "some other reason"
      end
    end

    context "when complaint status_memo is referred_to" do
      before do
        closed_status = ComplaintStatus.where(name: "Closed").first
        complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, status_memo: "another agency", status_memo_type: :close_referred_to}] 
        complaint.save
        visit complaint_path('en', complaint.id)
        edit_complaint
      end

      it "should show the status_memo value in the button" do
        expect(page.find('#status_memo_prompt').text).to eq "Referred to: another agency"
        click_button('Referred to: another agency')
        expect(page.find('#referred').value).to eq "another agency"
      end
    end
  end

  describe "apply closed status, select preset close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    let(:assignee){ complaint.assigns.first.assignee.first_last_name }
    let(:descriptions){ ['Closed, No jurisdiction','Assessment, Information pending', assignee, 'Registered'] }

    it "should show warnings until preset reason is selected" do
      # starts with status: assessment memo: Information pending
      choose('closed')
      click_button('Close memo')
      page.find('li#preset', text: 'No jurisdiction').click
      expect{edit_save}.to change{StatusChange.count}.by 1
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq closed_status.id
      expect(StatusChange.most_recent_first.first.status_memo).to eq "No jurisdiction"
      expect(all('#complaint #timeline .timeline_event .event_description').map(&:text)).to eq descriptions
    end
  end

  describe "apply closed status, enter 'other' close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    let(:assignee){ complaint.assigns.first.assignee.first_last_name }
    let(:descriptions){ ['Closed, some other reason','Assessment, Information pending', assignee, 'Registered'] }

    it "should show warnings until preset reason is selected" do
      choose('closed')
      click_button('Close memo')
      fill_in('other', with: "some other reason")
      expect{edit_save}.to change{StatusChange.count}.by 1
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq closed_status.id
      expect(StatusChange.most_recent_first.first.status_memo).to eq "some other reason"
      expect(all('#complaint #timeline .timeline_event .event_description').map(&:text)).to eq descriptions
    end
  end

  describe "apply closed status, enter 'referred to' close memo" do
    let(:closed_status){ ComplaintStatus.where(name: "Closed").first }
    let(:assignee){ complaint.assigns.first.assignee.first_last_name }
    let(:descriptions){ ['Closed, Referred to: another agency','Assessment, Information pending', assignee, 'Registered'] }

    it "should show warnings until preset reason is selected" do
      choose('closed')
      click_button('Close memo')
      fill_in('referred', with: "another agency")
      expect{edit_save}.to change{StatusChange.count}.by 1
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq closed_status.id
      expect(StatusChange.most_recent_first.first.status_memo).to eq "Referred to: another agency"
      expect(all('#complaint #timeline .timeline_event .event_description').map(&:text)).to eq descriptions
    end
  end

  describe "apply investigation status" do
    let(:investigation_status){ ComplaintStatus.where(name: "Investigation").first }
    it "should show warnings until preset reason is selected" do
      choose('investigation')
      expect{edit_save}.to change{StatusChange.count}.by 1
      expect(StatusChange.most_recent_first.first.complaint_status_id).to eq investigation_status.id
      expect(StatusChange.most_recent_first.first.status_memo).to be_blank
    end
  end

  describe "persistence of original attribute" do
    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, status_memo: "No jurisdiction", status_memo_type: :close_preset}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should persist the original status_memo attribute when selecting another status and returning to closed" do
      expect(page.find('#status_memo_prompt').text).to eq "No jurisdiction"
      choose('Assessment')
      check('Information pending')
      choose('Closed')
      expect(page.find('#status_memo_prompt').text).to eq "No jurisdiction"
      choose('Investigation')
      choose('Closed')
      expect(page.find('#status_memo_prompt').text).to eq "No jurisdiction"
    end
  end

  describe "change from closed to investigation status and save... status_memo not submitted" do
    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, status_memo: "No jurisdiction", status_memo_type: :close_preset}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should zeroize status_memo before saving" do
      choose('Investigation')
      edit_save
      expect(complaint.reload.current_status.status_memo).to be_blank
      expect(complaint.reload.current_status.complaint_status.name).to eq "Investigation"
    end
  end

  describe "when a status has assessment memo" do
    before do
      assessment_status = ComplaintStatus.where(name: "Assessment").first
      complaint.status_changes_attributes = [{complaint_status_id: assessment_status.id, status_memo: "Information pending", status_memo_type: :assessment}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should indicate the presence of the assessment memo" do
      expect(page.find('input#assessment_memo')).to be_checked
      choose('Closed')
      expect(page.find('#status_memo_prompt').text).to eq "Close memo"
      choose('Assessment')
      check('assessment_memo')
      choose('Closed')
      expect(page.find('#status_memo_prompt').text).to eq "Close memo"
    end
  end

  describe 'assign assessment status' do
    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, status_memo: "No jurisdiction", status_memo_type: :close_preset}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "should show assessment memo" do
      expect(page.find('input#closed')).to be_checked
      expect(page.find('#status_memo_prompt').text).to eq "No jurisdiction"
      choose('Assessment')
      check('assessment_memo')
      edit_save
      expect(complaint.reload.current_status.complaint_status.name).to eq "Assessment"
      expect(complaint.reload.current_status.status_memo).to eq "Information pending"
      expect(page.all('#timeline .timeline_event .event_label').first.text).to eq "Status change"
      expect(page.all('#timeline .timeline_event .event_description').first.text).to eq "Assessment, Information pending"
      edit_complaint
      expect(page.find('input#assessment')).to be_checked
      expect(page.find('input#assessment_memo')).to be_checked
    end
  end

  describe "case transfer" do
    let(:office_name){ OfficeGroup.national_regional_provincial.map(&:offices).flatten.first.name }
    let(:branch_office){ Office.branches.first.name }
    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, status_memo: "No jurisdiction", status_memo_type: :close_preset}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "shows case transfer within status timeline" do
      expect(page.all('select#transferee option').count).to eq Office.count
      select(office_name, :from => "transferee")
      expect{edit_save}.to change{ComplaintTransfer.count}.by(1)
      expect(complaint.complaint_transfers.merge(ComplaintTransfer.most_recent_for_complaint).first.user_id).to eq User.first.id
      expect(page.all('#timeline .timeline_event .event_label').first.text).to eq "Transferred to"
      expect(page.all('#timeline .timeline_event .event_description').first.text).to eq office_name
      expect(page.all('#timeline .timeline_event .user_name').first.text).to eq User.first.first_last_name
      expect(page.all('#timeline .timeline_event .date').first.text).to eq DateTime.now.to_s(:js_view)
    end

    it "does not add transfers when none are selected" do
      expect{edit_save}.not_to change{ComplaintTransfer.count}
    end
  end

  describe "case jurisdiction assignment" do
    let(:branch_office){ Office.branches.first.name }

    before do
      closed_status = ComplaintStatus.where(name: "Closed").first
      complaint.status_changes_attributes = [{complaint_status_id: closed_status.id, status_memo: "No jurisdiction", status_memo_type: :close_preset}] 
      complaint.save
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "shows case assignment to one of four investigative branches within timeline" do
      #see para 4.2.3 "Determine jurisdiction"
      expect(page.all('select#jurisdiction_branch option').count).to eq Office.branches.count + 1
      select(branch_office, from: "jurisdiction_branch")
      expect{edit_save}.to change{JurisdictionAssignment.count}.by(1)
      expect(complaint.jurisdiction_assignments.merge(JurisdictionAssignment.most_recent_for_complaint).first.user_id).to eq User.first.id
      expect(page.all('#timeline .timeline_event .event_label').first.text).to eq "Jurisdiction assigned"
      expect(page.all('#timeline .timeline_event .event_description').first.text).to eq branch_office
      expect(page.all('#timeline .timeline_event .user_name').first.text).to eq User.first.first_last_name
      expect(page.all('#timeline .timeline_event .date').first.text).to eq DateTime.now.to_s(:js_view)
    end
  end

  describe "staff assignment" do
    let(:assigner){ User.first.first_last_name }
    let!(:assignee){ FactoryBot.create(:user) }

    before do
      visit complaint_path('en', complaint.id)
      edit_complaint
    end

    it "shows the staff assignment in the timeline" do
      expect(page.all('select#assignee option').count).to eq User.count + 1
      select(assignee.first_last_name, from: 'assignee')
      expect{edit_save}.to change{Assign.count}.by(1)
      expect(complaint.assigns.first.user_id).to eq assignee.id
      expect(page.all('#timeline .timeline_event .event_label').first.text).to eq "Assigned to"
      expect(page.all('#timeline .timeline_event .event_description').first.text).to eq assignee.first_last_name
      expect(page.all('#timeline .timeline_event .user_name').first.text).to eq assigner
      expect(page.all('#timeline .timeline_event .date').first.text).to eq DateTime.now.to_s(:js_view)
    end
  end

end
