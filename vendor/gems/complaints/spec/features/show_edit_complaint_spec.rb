require 'rails_helper'
$:.unshift File.expand_path '../../helpers', __FILE__
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'complaints_spec_helpers'
require 'area_subarea_common_helpers'
require 'upload_file_helpers'
require 'active_storage_helpers'
require 'parse_email_helpers'

feature 'edit complaint', js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers
  include AreaSubareaCommonHelpers
  include UploadFileHelpers
  include ActiveStorageHelpers
  include ParseEmailHelpers

  before do
    populate_database(:individual_complaint)
    visit complaint_path(:en, IndividualComplaint.first.id)
  end

  it "changes complaint current status by adding a status_change" do
    edit_complaint
    expect(page).to have_checked_field "open"
    choose "closed"
    expect{ edit_save }.to change{ IndividualComplaint.first.current_status }.from("Open").to("Closed")
    expect( all('#status_changes .status_change').last.text ).to match "Closed"
    expect( all('#status_changes .date').last.text ).to match /#{Date.today.strftime("%b %-e, %Y")}/
    user = User.find_by(:login => 'admin')
    expect( all('#status_changes .user_name').last.text ).to match /#{user.first_last_name}/
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
    uncheck_agency("SAA")
    check_agency("MAF")
    # DOCUMENTS
    attach_file("complaint_fileinput", upload_document)
    fill_in("attached_document_title", :with => "added complaint document")
    expect(page).to have_selector("#complaint_documents .document .filename", :text => "first_upload_file.pdf")
    select_datepicker_date("#date_received",Date.today.year,Date.today.month,23)
    sleep(0.2) # javascript
    expect(page.find('#date_received').value).to eq "#{Date.today.strftime('%b 23, %Y')}"

    expect{ edit_save }.to change{ IndividualComplaint.find(1).lastName }.to("Normal").
                       and change{ IndividualComplaint.find(1).firstName }.to("Norman").
                       and change{ IndividualComplaint.find(1).city }.to("Normaltown").
                       and change{ IndividualComplaint.find(1).home_phone }.to("555-1212").
                       and change{ IndividualComplaint.find(1).assignees.count }.by(1).
                       and change{ IndividualComplaint.find(1).complaint_documents.count }.by(1).
                       and change{ stored_files_count }.by(1).
                       and change { ActionMailer::Base.deliveries.count }.by(1)

    expect( IndividualComplaint.first.title ).to eq "kahunga"
    expect( IndividualComplaint.first.complained_to_subject_agency ).to eq false
    expect( IndividualComplaint.first.dob ).to eq "19/08/1950"
    expect( IndividualComplaint.first.details ).to eq "the boy stood on the burning deck"
    expect( IndividualComplaint.first.desired_outcome ).to eq "Things are more better"
    expect( IndividualComplaint.first.complaint_area.name ).to eq "Special Investigations Unit"
    expect( IndividualComplaint.first.good_governance_subareas.map(&:name) ).to match_array [ "Failure to act", "Contrary to Law", "Oppressive", "Private"]
    expect( IndividualComplaint.first.good_governance_subareas.first.name ).to eq "Failure to act"
    expect( IndividualComplaint.first.human_rights_subareas.count ).to eq 1
    expect( IndividualComplaint.first.human_rights_subareas.first.name ).to eq "ICESCR"
    expect( IndividualComplaint.first.special_investigations_unit_subareas.count ).to eq 1
    expect( IndividualComplaint.first.special_investigations_unit_subareas.first.name ).to eq "Not properly investigated"
    expect( IndividualComplaint.first.assignees ).to include User.admin.last
    expect( IndividualComplaint.first.agencies.map(&:name) ).to include "MAF"
    expect( IndividualComplaint.first.agencies.count ).to eq 1
    expect( IndividualComplaint.first.date_received.to_date).to eq Date.new(Date.today.year, Date.today.month, 23)

    expect(page).to have_selector('#complainant_dob', :text => "Aug 19, 1950")
    expect(page).to have_selector('#desired_outcome', :text => "Things are more better")
    expect(page).to have_selector('#complaint_details', :text => "the boy stood on the burning deck")
    expect(page).to have_selector('#complained_to_subject_agency', :text => "no")
    expect(page).to have_selector('#date',:text => Date.new(Date.today.year, Date.today.month, 23).strftime("%b %-e, %Y"))

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

    within agencies do
      expect(all('.agency').map(&:text)).to include "MAF"
    end

    within complaint_documents do
      expect(page.all('#complaint_documents .complaint_document .filename').map(&:text)).to include "first_upload_file.pdf"
      expect(page.all('#complaint_documents .complaint_document .title').map(&:text)).to include "added complaint document"
    end

    expect(page).to have_selector("#assignees .assignee .name", :text => User.admin.last.first_last_name )

    user = User.staff.last
    expect( email.subject ).to eq "Notification of complaint assignment"
    expect( addressee ).to eq user.first_last_name
    expect( complaint_url ).to match (/#{Regexp.escape complaints_path(:en,case_reference:IndividualComplaint.first.case_reference.to_s)}$/i)
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
    check_agency("ACC")
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
    expect(find('#date_received').value).to eq original_complaint.date_received.strftime("%b %-e, %Y")
    new_assignee_id = page.evaluate_script("complaint.get('new_assignee_id')")
    expect(new_assignee_id).to be_zero
    expect(find('#current_assignee').text).to eq original_complaint.assignees.first.first_last_name
    expect(page.find(".complaint_area ##{original_complaint.complaint_area.key}")).to be_checked
    expect(page.find_field("ACC")).not_to be_checked
    expect(page.find_field("SAA")).to be_checked
    expect(page).not_to have_selector("#attached_document_title")
    expect(page).not_to have_selector(".title .filename")
  end

  it "resets errors if editing is cancelled" do
    edit_complaint
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
    uncheck_agency("SAA")
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
    uncheck_agency("SAA")
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
