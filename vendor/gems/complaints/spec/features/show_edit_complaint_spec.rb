require 'rails_helper'
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'complaints_spec_helpers'
require 'area_subarea_common_helpers'
require 'upload_file_helpers'
require 'active_storage_helpers'
require 'parse_email_helpers'

feature 'show complaint with multiple agencies', js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers

  let(:individual_complaint){ IndividualComplaint.first }
  let(:first_agency){ LocalMunicipality.first }
  let(:first_province_name){ first_agency.district_municipality.province.name }
  let(:first_province_key){ first_province_name.gsub(/\s/,'_').downcase }
  let(:first_district_name){ first_agency.district_municipality.name }
  let(:first_district_key){ first_district_name.gsub(/\s/,'_').downcase }
  let(:second_agency){ LocalMunicipality.second }
  let(:second_province_name){ second_agency.district_municipality.province.name }
  let(:second_province_key){ second_province_name.gsub(/\s/,'_').downcase }
  let(:second_district_name){ second_agency.district_municipality.name }
  let(:second_district_key){ second_district_name.gsub(/\s/,'_').downcase }

  before do
    populate_database(:individual_complaint)
    visit complaint_path(:en, individual_complaint.id)
  end

  it "should list multiple agencies" do
    expect(page.all('#agencies .agency').map(&:text)).to match_array individual_complaint.agencies.map(&:description)
    edit_complaint
    expect(page.all('#agencies_select').count).to eq 2
    expect(page).to have_selector('#add_agency')
    # first two agencies are assigned, both local municipalities
    within page.all('.agency_select_container')[0] do
      expect(page.find('#agencies_select option', text: 'Local')).to be_selected
      expect(page.find('#provinces_select option', text: first_province_name)).to be_selected
      expect(page.find("##{first_province_key} option", text: first_district_name)).to be_selected
      expect(page.find("##{first_district_key} option", text: first_agency.name)).to be_selected
      expect(page).to have_selector('#remove_agency')
    end
    within page.all('.agency_select_container')[1] do
      expect(page.find('#agencies_select option', text: 'Local')).to be_selected
      expect(page.find('#provinces_select option', text: second_province_name)).to be_selected
      expect(page.find("##{second_province_key} option", text: second_district_name)).to be_selected
      expect(page.find("##{second_district_key} option", text: second_agency.name)).to be_selected
      expect(page).to have_selector('#remove_agency')
    end
  end

  it "should add an agency selector" do
    edit_complaint
    expect{page.find('#add_agency').click}.to change{ page.all('.agency_select_container').count }.from(2).to(3)
  end

  it "should remove an agency selector" do
    edit_complaint
    expect{page.all('#remove_agency').first.click}.to change{ page.all('.agency_select_container').count }.from(2).to(1)
  end

  it "should not remove the last agency selector" do
    edit_complaint
    page.all('#remove_agency').first.click
    expect(page).not_to have_selector('#remove_agency')
  end
end

feature 'edit complaint', js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers
  include AreaSubareaCommonHelpers
  include UploadFileHelpers
  include ActiveStorageHelpers
  include ParseEmailHelpers

  let(:closed_complaint){ IndividualComplaint.all.select{|c| c.current_status.complaint_status.name == "Closed"}.first }
  let(:individual_complaint){ IndividualComplaint.first }
  let(:lesedi){ LocalMunicipality.where(name: 'Lesedi').first }
  let(:emfuleni){ LocalMunicipality.where(name: 'Emfuleni').first }

  before do
    populate_database(:individual_complaint)
    individual_complaint.update(agency_ids: [lesedi.id])
    visit complaint_path(:en, individual_complaint.id)
  end

  it "changes complaint current status by adding a status_change" do
    edit_complaint
    expect(page).to have_checked_field "Registered"
    choose "Assessment"
    expect{ edit_save }.to change{ IndividualComplaint.first.current_status.complaint_status.name }.from("Registered").to("Assessment")
    expect( all('#timeline .timeline_event').first.text ).to match "Assessment"
    expect( all('#timeline .timeline_event').last.text ).to match "Registered"
    expect( all('#timeline .date').first.text ).to match /#{Date.today.strftime("%b %-e, %Y")}/
    user = User.find_by(:login => 'admin')
    expect( all('#timeline .user_name').first.text ).to match /#{user.first_last_name}/
  end

  it "edits a closed complaint with a preset close memo" do
    closed_complaint.status_changes.most_recent_first.first.update(status_memo_type: :close_preset, status_memo: "No jurisdiction")
    visit complaint_path(:en, closed_complaint.id)
    edit_complaint
    expect(page.find('#status_memo_prompt').text).to eq "No jurisdiction"
    open_close_memo_menu
  end

  it "edits a closed complaint with a referral close memo" do
    closed_complaint.status_changes.most_recent_first.first.update(status_memo_type: :close_referred_to, status_memo: "another agency")
    visit complaint_path(:en, closed_complaint.id)
    edit_complaint
    expect(page.find('#status_memo_prompt').text).to eq "Referred to: another agency"
    open_close_memo_menu
    expect(page.find('#status_memo #referred').value).to eq "another agency"
  end

  it "edits a closed complaint with a user-entered reason close memo" do
    closed_complaint.status_changes.most_recent_first.first.update(status_memo_type: :close_other_reason, status_memo: "some other reason")
    visit complaint_path(:en, closed_complaint.id)
    edit_complaint
    expect(page.find('#status_memo_prompt').text).to eq "some other reason"
    open_close_memo_menu
    expect(page.find('#status_memo #other').value).to eq "some other reason"
  end

  it "edits a complaint" do
    edit_complaint
    # COMPLAINANT
    fill_in('lastName', :with => "Normal")
    fill_in('firstName', :with => "Norman")
    fill_in('title', :with => "kahunga")
    fill_in('dob', :with => "19/08/1950")
    fill_in('city', :with => "Normaltown")
    fill_in('home_phone', :with => "555-1212")
    fill_in('complaint_details', :with => "the boy stood on the burning deck")
    fill_in('desired_outcome', :with => "Things are more better")
    choose('complained_to_subject_agency_no')
    # ASSIGNEE
    select(User.staff.last.first_last_name, :from => "assignee")
    # MANDATE
    choose('special_investigations_unit') # originally had human rights mandate
    # BASIS
    uncheck_subarea(:good_governance, "Delayed action") # originally had "Delayed action", "Failure to act", "Contrary to Law", "Oppressive", "Private"
    uncheck_subarea(:human_rights, "CAT") # originall had "CAT" "ICESCR"
    uncheck_subarea(:special_investigations_unit, "Unreasonable delay") #originally had "Unreasonable delay" "Not properly investigated"
    # AGENCY
    select_local_municipal_agency(page.all('.agency_select_container')[0],'Emfuleni')
    # DOCUMENTS
    attach_file("complaint_fileinput", upload_document)
    fill_in("attached_document_title", :with => "added complaint document")
    expect(page).to have_selector("#complaint_documents .document .filename", :text => "first_upload_file.pdf")
    select_datepicker_date("#date_received",Date.today.year,Date.today.month,23)
    sleep(0.2) # javascript
    expect(page.find('#date_received').value).to eq "#{Date.today.strftime('23/%m/%Y')}"

    expect{ edit_save }.to change{ IndividualComplaint.find(1).lastName }.to("Normal").
                       and change{ IndividualComplaint.find(1).firstName }.to("Norman").
                       and change{ IndividualComplaint.find(1).city }.to("Normaltown").
                       and change{ IndividualComplaint.find(1).home_phone }.to("555-1212").
                       and change{ IndividualComplaint.find(1).assignees.count }.by(1).
                       and change{ IndividualComplaint.find(1).complaint_documents.count }.by(1).
                       and change{ stored_files_count }.by(1).
                       and change { ActionMailer::Base.deliveries.count }.by(1)

    # first Complaint has current status "registered"
    # last Complaint has current status "closed"
    # here we're editing the first complaint
    expect( individual_complaint.reload.title ).to eq "kahunga"
    expect( individual_complaint.reload.complained_to_subject_agency ).to eq false
    expect( individual_complaint.reload.dob ).to eq "19/08/1950"
    expect( individual_complaint.reload.details ).to eq "the boy stood on the burning deck"
    expect( individual_complaint.reload.desired_outcome ).to eq "Things are more better"
    expect( individual_complaint.reload.complaint_area.name ).to eq "Special Investigations Unit"
    expect( individual_complaint.reload.good_governance_subareas.map(&:name) ).to match_array [ "Failure to act", "Contrary to Law", "Oppressive", "Private"]
    expect( individual_complaint.reload.good_governance_subareas.first.name ).to eq "Failure to act"
    expect( individual_complaint.reload.human_rights_subareas.count ).to eq 1
    expect( individual_complaint.reload.human_rights_subareas.first.name ).to eq "ICESCR"
    expect( individual_complaint.reload.special_investigations_unit_subareas.count ).to eq 1
    expect( individual_complaint.reload.special_investigations_unit_subareas.first.name ).to eq "Not properly investigated"
    expect( individual_complaint.reload.assignees ).to include User.admin.last
    expect( individual_complaint.reload.agencies.map(&:name) ).to include "Emfuleni"
    expect( individual_complaint.reload.agencies.count ).to eq 1
    expect( individual_complaint.reload.date_received.to_date).to eq Date.new(Date.today.year, Date.today.month, 23)

    expect(page).to have_selector('#complainant_dob', :text => "19/08/1950")
    expect(page).to have_selector('#desired_outcome', :text => "Things are more better")
    expect(page).to have_selector('#complaint_details', :text => "the boy stood on the burning deck")
    expect(page).to have_selector('#complained_to_subject_agency', :text => "no")
    expect(page).to have_selector('#date',:text => Date.new(Date.today.year, Date.today.month, 23).strftime(Complaint::DateFormat))

    within good_governance_area do
      IndividualComplaint.first.complaint_subareas.good_governance.map(&:name).each do |subarea_name|
        expect(page).to have_selector('.subarea', :text => subarea_name)
      end
    end

    within human_rights_area do
      IndividualComplaint.first.complaint_subareas.human_rights.map(&:name).each do |subarea_name|
        expect(page).to have_selector('.subarea', :text => subarea_name)
      end
    end

    within special_investigations_unit_area do
      IndividualComplaint.first.complaint_subareas.special_investigations_unit.map(&:name).each do |subarea_name|
        expect(page).to have_selector('.subarea', :text => subarea_name)
      end
    end

    expect(find('.agency').text).to eq emfuleni.description

    within complaint_documents do
      expect(page.all('#complaint_documents .complaint_document .filename').map(&:text)).to include "first_upload_file.pdf"
      expect(page.all('#complaint_documents .complaint_document .title').map(&:text)).to include "added complaint document"
    end

    expect(page).to have_selector("#timeline .timeline_event .event_description", :text => User.admin.last.first_last_name )

    user = User.staff.last
    expect( email.subject ).to eq "Notification of complaint assignment"
    expect( addressee ).to eq user.first_last_name
    expect( complaint_url ).to match (/#{Regexp.escape complaint_path('en',Complaint.first.id)}$/i)
    expect( complaint_url ).to match (/^https:\/\/#{SITE_URL}/)
    expect( header_field('List-Unsubscribe-Post')).to eq "List-Unsubscribe=One-Click"
    expect( header_field('List-Unsubscribe')).to eq admin_unsubscribe_url(:en,user.id, user.reload.unsubscribe_code, host: SITE_URL, protocol: :https)
    expect( header_field('From')).to eq "NHRI Hub Administrator<no_reply@nhri-hub.com>"
    expect( unsubscribe_url ).to match (/\/en\/admin\/unsubscribe\/#{user.id}\/[0-9a-f]{40}$/) # unsubscribe code
  end

  it "edits a complaint with no changes to the status" do # b/c there was a bug
    edit_complaint
    expect{ edit_save }.not_to change{ IndividualComplaint.first.status_changes.count }
  end

  it "edits a complaint with no change of assignee" do
    edit_complaint
    expect{ edit_save }.to change{ IndividualComplaint.first.assignees.count }.by(0)
                       .and change { ActionMailer::Base.deliveries.count }.by(0)
  end

  it "edits a complaint, deleting a file" do
    edit_complaint
    #expect(page).to have_selector(".complaint .row.collapse.in", :count => 13) # make sure expanded info is fully rendered before proceeding with the deletion
    expect{delete_document; confirm_deletion; wait_for_ajax}.to change{ IndividualComplaint.first.complaint_documents.count }.by(-1).
                                          and change{ documents.count }.by(-1)
  end

  it "restores previous values when editing is cancelled" do
    new_assignee_id = page.evaluate_script("complaint.get('new_assignee_id')")
    original_complaint = IndividualComplaint.first
    edit_complaint
    fill_in('lastName', :with => "Normal")
    fill_in('firstName', :with => "Norman")
    fill_in('title', :with => "barista")
    fill_in('city', :with => "Normaltown")
    fill_in('home_phone', :with => "555-1212")
    check_subarea(:good_governance, "Private")
    check_subarea(:good_governance, "Contrary to Law")
    fill_in('dob', :with => "11/11/1820")
    fill_in('email', :with => "harry@haricot.net")
    select_male_gender
    fill_in('complaint_details', :with => "a long story about lots of stuff")
    fill_in('desired_outcome', :with => "bish bash bosh")
    choose('complained_to_subject_agency_yes')
    select_datepicker_date("#date_received",Date.today.year,Date.today.month,9)
    select(User.admin.last.first_last_name, :from => "assignee")
    choose('special_investigations_unit')
    select_local_municipal_agency(page.all('.agency_select_container')[0],'Emfuleni')
    attach_file("complaint_fileinput", upload_document)
    fill_in("attached_document_title", :with => "some text any text")
    edit_cancel
    sleep(0.5) # seems like a huge amount of time to wait for javascript, but this is what it takes for reliable operation in chrome
    edit_complaint
    expect(page.find('#lastName').value).to eq original_complaint.lastName
    expect(page.find('#firstName').value).to eq original_complaint.firstName
    expect(page.find('#title').value).to eq original_complaint.title
    expect(page.find('#city').value).to eq original_complaint.city
    expect(page.find('#home_phone').value).to eq original_complaint.home_phone
    ["Delayed action", "Failure to act", "Contrary to Law", "Oppressive", "Private", "CAT", "ICESCR", "Unreasonable delay", "Not properly investigated"].each do |subarea_name|
      expect(page.find('.subarea', :text => subarea_name).find('input')).to be_checked
    end
    expect(page.find('#dob').value).to eq original_complaint.dob
    expect(page.find('#email').value).to eq original_complaint.email.to_s
    expect(page.find('#m')).not_to be_checked
    expect(page.find('#complaint_details').value).to eq original_complaint.details
    expect(page.find('#desired_outcome').value).to eq original_complaint.desired_outcome.to_s
    expect(page.find('#complained_to_subject_agency_yes')).not_to be_checked
    expect(find('#date_received').value).to eq original_complaint.date_received.strftime(Complaint::DateFormat)
    new_assignee_id = page.evaluate_script("complaint.get('new_assignee_id')")
    expect(new_assignee_id).to be_zero
    expect(find('#current_assignee').text).to eq original_complaint.assignees.first.first_last_name
    expect(page.find(".complaint_area ##{original_complaint.complaint_area.key}")).to be_checked
    expect(page.find('select#sedibeng option', text:'Lesedi')).to be_selected
    expect(page).not_to have_selector("#attached_document_title")
    expect(page).not_to have_selector(".title .filename")
  end

  it "resets errors if editing is cancelled" do
    edit_complaint # Complaint.first
    # COMPLAINANT
    fill_in('lastName', :with => "")
    fill_in('firstName', :with => "")
    fill_in('city', :with => "")
    fill_in('home_phone', :with => "555-1212")
    fill_in('dob', :with => "")
    fill_in('complaint_details', :with => "")
    # MANDATE
    choose('special_investigations_unit') # originally had human rights mandate
    # BASIS
    ["Delayed action", "Failure to act", "Contrary to Law", "Oppressive", "Private"].each do |subarea_name|
      uncheck_subarea(:good_governance, subarea_name )
    end
    uncheck_subarea(:human_rights, "CAT") # originall had "CAT" "ICESCR"
    uncheck_subarea(:human_rights, "ICESCR") # originall had "CAT" "ICESCR"
    uncheck_subarea(:special_investigations_unit, "Unreasonable delay") #originally had "Unreasonable delay" "Not properly investigated"
    uncheck_subarea(:special_investigations_unit, "Not properly investigated") #originally had "Unreasonable delay" "Not properly investigated"
    # AGENCY
    select_local_municipal_agency(page.all('.agency_select_container')[0],'Emfuleni')
    expect{ edit_save }.not_to change{ IndividualComplaint.first}

    expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).to have_selector('#city_error', :text => 'You must enter a city')
    expect(page).to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")

    edit_cancel
    sleep(0.5) # seems like a huge amount of time to wait for javascript, but this is what it takes for reliable operation in chrome
    edit_complaint
    expect(page).not_to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).not_to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).not_to have_selector('#city_error', :text => 'You must enter a city')
    expect(page).not_to have_selector('#mandate_name_error', :text => 'You must select an area')
    expect(page).not_to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    expect(page).not_to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).not_to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "edits a complaint to invalid values" do
    edit_complaint
    # COMPLAINANT
    fill_in('lastName', :with => "")
    fill_in('firstName', :with => "")
    fill_in('city', :with => "")
    fill_in('home_phone', :with => "555-1212")
    fill_in('dob', :with => "")
    fill_in('complaint_details', :with => "")
    # BASIS
    ["Delayed action", "Failure to act", "Contrary to Law", "Oppressive", "Private"].each do |subarea_name|
      uncheck_subarea(:good_governance, subarea_name )
    end
    uncheck_subarea(:human_rights, "CAT") # originall had "CAT" "ICESCR"
    uncheck_subarea(:human_rights, "ICESCR") # originall had "CAT" "ICESCR"
    uncheck_subarea(:special_investigations_unit, "Unreasonable delay") #originally had "Unreasonable delay" "Not properly investigated"
    uncheck_subarea(:special_investigations_unit, "Not properly investigated") #originally had "Unreasonable delay" "Not properly investigated"
    # AGENCY
    select_local_municipal_agency(page.all('.agency_select_container')[0],'Emfuleni')
    expect{ edit_save }.not_to change{ IndividualComplaint.first}

    expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).to have_selector('#city_error', :text => 'You must enter a city')
    expect(page).to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    fill_in('lastName', :with => "Normal")
    expect(page).not_to have_selector('#lastName_error', :text => "You must enter a last name")
    fill_in('firstName', :with => "Norman")
    expect(page).not_to have_selector('#firstName_error', :text => "You must enter a first name")
    fill_in('city', :with => "Leaden Roding")
    expect(page).not_to have_selector('#city_error', :text => 'You must enter a city')
    choose('special_investigations_unit')
    expect(page).not_to have_selector('#mandate_id_error', :text => 'You must select an area')
    check_subarea(:special_investigations_unit, "Unreasonable delay")
    expect(page).not_to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    fill_in('dob', :with => "1950/08/19")
    expect(page).not_to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    fill_in('complaint_details', :with => "bish bash bosh")
    expect(page).not_to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end
end
