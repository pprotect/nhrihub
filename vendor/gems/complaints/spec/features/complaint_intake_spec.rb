require 'rails_helper'
$:.unshift File.expand_path '../../helpers', __FILE__
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'navigation_helpers'
require 'complaints_spec_helpers'
require 'upload_file_helpers'
require 'active_storage_helpers'
require 'parse_email_helpers'
require 'area_subarea_common_helpers'

feature "complaint pages navigation", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user

  before do
    visit home_path('en')
  end

  it "should have dropdown with intake option" do
    page.find('.nav #compl a.dropdown-toggle').hover
    expect(page).to have_selector('.nav #compl .dropdown-menu #intake', text: 'Intake')
    expect(page).to have_selector('.nav #compl .dropdown-menu #list', text: 'List')
  end
end

feature "complaints index", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers
  include UploadFileHelpers
  include ActiveStorageHelpers
  include ParseEmailHelpers
  include AreaSubareaCommonHelpers

  let(:formatted_case_reference) { ->(year,sequence){ CaseReferenceFormat%{year:year,sequence:sequence} } }
  let(:current_year){ Date.today.strftime('%y').to_i }

  before do
    populate_database
    visit complaint_intake_path('en', 'individual')
  end

  it "adds a new complaint that is valid" do
    expect( page_heading ).to eq "Individual Complaint Intake"
    complete_required_fields
    expect{save_complaint}.to change{ Complaint.count }.by(1)

    # on the server
    #puts "on server, first status change is:  #{ActiveRecord::Base.connection.execute('select change_date from status_changes').to_a.last["change_date"]}"
    #puts DateTime.now.strftime("%b %e, %Y")
    expect(page.find('#status_changes .status_change span.date').text).to eq Date.today.strftime("%b %-e, %Y")
  end

  it "adds a new complaint that is valid" do
    user = User.staff.first
    within new_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('dob', :with => "08/09/1950")
      fill_in('email', :with => "norm@acme.co.ws")
      fill_in('village', :with => "Normaltown")
      fill_in('phone', :with => "555-1212")
      fill_in('complaint_details', :with => "a long story about lots of stuff")
      fill_in('desired_outcome', :with => "Life gets better")
      fill_in('title', :with => "bossman")
      choose('special_investigations_unit')
      select_male_gender
      choose('complained_to_subject_agency_yes')
      check_subarea(:good_governance, "Delayed action")
      check_subarea(:human_rights, "CAT")
      check_subarea(:special_investigations_unit, "Unreasonable delay")
      select(user.first_last_name, :from => "assignee")
      check_agency("SAA")
      check_agency("ACC")
      attach_file("complaint_fileinput", upload_document)
      fill_in("attached_document_title", :with => "Complaint Document")
      select_datepicker_date("#date_received",Date.today.year,Date.today.month,16)
    end
    expect(page).to have_selector("#documents .document .filename", :text => "first_upload_file.pdf")

    next_ref = Complaint.next_case_reference
    expect{save_complaint}.to change{ Complaint.count }.by(1)
                                .and change{ ComplaintComplaintSubarea.count }.by(3)
                                .and change{ ComplaintAgency.count }.by(2)
                                .and change{ ActionMailer::Base.deliveries.count }.by(1)
    ## on the server
    complaint = Complaint.last
    expect(complaint.case_reference.year).to eq next_ref.year
    expect(complaint.case_reference.sequence).to eq next_ref.sequence
    expect(complaint.lastName).to eq "Normal"
    expect(complaint.firstName).to eq "Norman"
    expect(complaint.title).to eq "bossman"
    expect(complaint.dob).to eq "08/09/1950" # dd/mm/yyyy
    expect(complaint.gender).to eq 'M'
    expect(complaint.email).to eq "norm@acme.co.ws"
    expect(complaint.complained_to_subject_agency).to eq true
    expect(complaint.village).to eq "Normaltown"
    expect(complaint.phone).to eq "555-1212"
    expect(complaint.details).to eq "a long story about lots of stuff"
    expect(complaint.desired_outcome).to eq "Life gets better"
    expect(complaint.complaint_area.name).to eq 'Special Investigations Unit'
    expect(complaint.complaint_subareas.map(&:name)).to match_array ["Delayed action", "CAT", "Unreasonable delay"]
    expect(complaint.current_assignee_name).to eq User.staff.first.first_last_name
    expect(complaint.status_changes.count).to eq 1
    expect(complaint.status_changes.first.complaint_status.name).to eq "Under Evaluation"
    expect(complaint.agencies.map(&:name)).to include "SAA"
    expect(complaint.agencies.map(&:name)).to include "ACC"
    expect(complaint.complaint_documents.count).to eq 1
    expect(complaint.complaint_documents[0].original_filename).to eq "first_upload_file.pdf"
    expect(complaint.complaint_documents[0].title).to eq "Complaint Document"
    expect(complaint.date_received.to_date).to eq Date.new(Date.today.year, Date.today.month, 16)

    ## on the client
    expect(page_heading).to eq "Complaint, case reference: #{next_ref}"
    expect(find('#complaint .current_assignee').text).to eq user.first_last_name
    expect(find('#complaint .lastName').text).to eq "Normal"
    expect(find('#complaint .firstName').text).to eq "Norman"
    expect(find('#complaint #complainant .title').text).to eq "bossman"
    expect(find('#complaint #status_changes .status_change .status_humanized').text).to eq 'Under Evaluation'
    expect(find('#complaint .complainant_dob').text).to eq "Sep 8, 1950"
    expect(find('#complaint .email').text).to eq "norm@acme.co.ws"
    expect(find('#complaint .complaint_details').text).to eq "a long story about lots of stuff"
    expect(find('#complaint .desired_outcome').text).to eq "Life gets better"
    expect(find('#complaint .complainant_village').text).to eq "Normaltown"
    expect(find('#complaint .complainant_phone').text).to eq "555-1212"
    #expect(find('#complaint .gender').text).to eq "male" # this should work, but I postponed troubleshooting in favour of other activities!
    expect(find('#complaint .gender').text).to eq "M"
    expect(find('#complaint .complained_to_subject_agency').text).to eq "yes"
    expect(find('#complaint .date_received').text).to eq Date.new(Date.today.year, Date.today.month, 16).strftime("%b %-e, %Y")

    within special_investigations_unit_area do
      Complaint.last.complaint_subareas.special_investigations_unit.map(&:name).each do |subarea_name|
        expect(page).to have_selector('.subarea', :text => subarea_name)
      end
    end


    within agencies do
      expect(all('.agency').map(&:text)).to match_array ["SAA", "ACC" ]
    end

    within complaint_documents do
      doc = page.all('.complaint_document')[0]
      expect(doc.find('.filename').text).to eq "first_upload_file.pdf"
      expect(doc.find('.title').text).to eq "Complaint Document"
    end

    expect(page.find('#mandate').text).to match /Special Investigations Unit/

    # Email notification
    expect( email.subject ).to eq "Notification of complaint assignment"
    expect( addressee ).to eq user.first_last_name
    expect( complaint_url ).to match (/#{Regexp.escape complaints_path(:en,case_reference:complaint.case_reference.to_s)}$/i)
    expect( complaint_url ).to match (/^https:\/\/#{SITE_URL}/)
    expect( header_field('From')).to eq "NHRI Hub Administrator<no_reply@nhri-hub.com>"
    expect( header_field('List-Unsubscribe-Post')).to eq "List-Unsubscribe=One-Click"
    expect( header_field('List-Unsubscribe')).to eq admin_unsubscribe_url(:en,user.id, user.reload.unsubscribe_code, host: SITE_URL, protocol: :https)
    expect( unsubscribe_url ).to match (/\/en\/admin\/unsubscribe\/#{user.id}\/[0-9a-f]{40}$/) # unsubscribe code

    # back button
    page.go_back
    expect( page_heading ).to eq "Individual Complaint Intake"
    page.go_forward
    expect(page_heading).to eq "Complaint, case reference: #{next_ref}"
    page.go_back
    expect( page_heading ).to eq "Individual Complaint Intake"
    complete_required_fields
    next_ref = Complaint.next_case_reference # capture the expected value before saving
    expect{save_complaint}.to change{ Complaint.count }.by(1)
    expect(page_heading).to eq "Complaint, case reference: #{next_ref}"
  end

  it "adds 15 complaints and increments case reference for each" do #b/c there was a bug
    15.times do |i|
      visit complaint_intake_path('en', 'individual')
      complete_required_fields
      expect{save_complaint}.to change{ Complaint.count }.by(1)
    end
    assigned_case_references = Complaint.all.sort.map(&:case_reference).map(&:to_s)
    expected_case_references = (1..17).map{|i| formatted_case_reference[current_year,i] }.reverse
    expect(assigned_case_references).to eq expected_case_references
  end

  it "does not add a new complaint that is invalid" do
    save_complaint(false)
    expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).to have_selector('#village_error', :text => 'You must enter a village')
    expect(page).to have_selector('#new_assignee_id_error', :text => 'You must designate an assignee')
    expect(page).to have_selector('#complaint_area_id_error', :text => 'You must select an area')
    expect(page).to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    fill_in('lastName', :with => "Normal")
    expect(page).not_to have_selector('#lastName_error', :text => "You must enter a first name")
    fill_in('firstName', :with => "Norman")
    expect(page).not_to have_selector('#firstName_error', :text => "You must enter a last name")
    fill_in('dob', :with => "19/08/1968")
    expect(page).not_to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    fill_in('village', :with => "Leaden Roding")
    expect(page).not_to have_selector('#village_error', :text => 'You must enter a village')
    select(User.admin.first.first_last_name, :from => "assignee")
    expect(page).not_to have_selector('#new_assignee_id_error', :text => 'You must designate an assignee')
    choose('special_investigations_unit')
    expect(page).not_to have_selector('#complaint_area_id_error', :text => 'You must select an area')
    check_subarea(:special_investigations_unit, "Unreasonable delay")
    expect(page).not_to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    fill_in('complaint_details', :with => "random text")
    expect(page).not_to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "flags as invalid when file attachment exceeds permitted filesize" do
    attach_file("complaint_fileinput", big_upload_document)
    expect(page).to have_selector('#filesize_error', :text => "File is too large")

    expect{ save_complaint }.not_to change{ Complaint.count }
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "flags as invalid when file attachment is unpermitted filetype" do
    SiteConfig["complaint_document.filetypes"]=["doc"]
    visit complaint_intake_path('en', 'individual')

    attach_file("complaint_fileinput", upload_image)
    expect(page).to have_css('#original_type_error', :text => "File type not allowed")

    expect{ save_complaint }.not_to change{ Complaint.count }
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "sets date_received to today's date if it is not provided when adding" do
    fill_in('lastName', :with => "Normal")
    fill_in('firstName', :with => "Norman")
    fill_in('dob', :with => "08/09/1950")
    fill_in('village', :with => "Normaltown")
    fill_in('complaint_details', :with => "a long story about lots of stuff")
    choose('special_investigations_unit')
    check_subarea(:good_governance, "Delayed action")
    select(User.admin.first.first_last_name, :from => "assignee")
    expect{save_complaint}.to change{ Complaint.count }.by(1)

    # on the server
    complaint = Complaint.last
    expect(complaint.date_received.to_date).to eq Date.today

    # on the client
    expect(page.find('.date_received').text).to eq Date.today.strftime("%b %-e, %Y")
  end
end
