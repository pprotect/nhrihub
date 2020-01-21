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
    page.find('.nav #compl .dropdown-menu #intake').hover
    expect(page).to have_selector('.nav #compl .dropdown-menu #organization', text: 'Organization')
  end
end

feature "organization complaint intake", :js => true do
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
    visit complaint_register_path('en', 'organization')
  end

  it "adds a new complaint that is valid" do
    expect( page_heading ).to eq "Organization Complaint Intake"
    complete_required_fields(:organization)
    expect{save_complaint}.to change{ Complaint.count }.by(1)

    # on the server
    #puts "on server, first status change is:  #{ActiveRecord::Base.connection.execute('select change_date from status_changes').to_a.last["change_date"]}"
    #puts DateTime.now.strftime("%b %e, %Y")
    expect(page.find('#status_changes .status_change span.date').text).to eq Date.today.strftime("%b %-e, %Y")
  end

  it "adds a new complaint that is valid" do
    user = User.staff.first
    fill_in('title', :with => "Ambassador")
    fill_in('contact_last_name', :with => "Normal")
    fill_in('contact_first_name', :with => "Norman")
    fill_in('physical_address', :with => '1311 Santa Rosa Avenue')
    fill_in('postal_address', :with => '8844 Sebastopol Road')
    fill_in('city', :with => "Normaltown")
    fill_in('province', with: 'Gondwanaland')
    fill_in('postal_code', with: '12345')
    fill_in('contact_email', :with => "norm@acme.co.ws")
    fill_in('contact_phone', :with => "555-1212")
    fill_in('contact_cell_phone', :with => "555-1212")
    fill_in('contact_fax', with: '832-4489')
    fill_in('organization_name', :with => 'Acme Corp')
    fill_in('organization_registration_number', :with => '1234abcd')
    choose('Fax')
    fill_in('complaint_details', :with => "a long story about lots of stuff")
    fill_in('desired_outcome', :with => "Life gets better")
    choose('special_investigations_unit')
    choose('complained_to_subject_agency_yes')
    select_datepicker_date("#date_received",Date.today.year,Date.today.month,16)
    check_subarea(:good_governance, "Delayed action")
    check_subarea(:human_rights, "CAT")
    check_subarea(:special_investigations_unit, "Unreasonable delay")
    select(user.first_last_name, :from => "assignee")
    check_agency("SAA")
    check_agency("ACC")
    attach_file("complaint_fileinput", upload_document)
    fill_in("attached_document_title", :with => "Complaint Document")

    expect(page).to have_selector("#complaint_documents .document .filename", :text => "first_upload_file.pdf")

    next_ref = Complaint.next_case_reference
    expect{save_complaint}.to change{ Complaint.count }.by(1)
                                .and change{ ComplaintComplaintSubarea.count }.by(3)
                                .and change{ ComplaintAgency.count }.by(2)
                                .and change{ ActionMailer::Base.deliveries.count }.by(1)
    ## on the server
    complaint = Complaint.last
    expect(complaint).to be_a(OrganizationComplaint)
    expect(complaint.case_reference.year).to eq next_ref.year
    expect(complaint.case_reference.sequence).to eq next_ref.sequence
    expect(complaint.title).to eq "Ambassador"
    expect(complaint.lastName).to eq "Normal"
    expect(complaint.firstName).to eq "Norman"
    expect(complaint.physical_address).to eq "1311 Santa Rosa Avenue"
    expect(complaint.postal_address).to eq "8844 Sebastopol Road"
    expect(complaint.city).to eq "Normaltown"
    expect(complaint.province).to eq "Gondwanaland"
    expect(complaint.postal_code).to eq "12345"
    expect(complaint.email).to eq "norm@acme.co.ws"
    expect(complaint.home_phone).to eq "555-1212"
    expect(complaint.cell_phone).to eq "555-1212"
    expect(complaint.fax).to eq "832-4489"
    expect(complaint.organization_name).to eq "Acme Corp"
    expect(complaint.organization_registration_number).to eq '1234abcd'
    expect(complaint.preferred_means).to eq 'fax'
    expect(complaint.details).to eq "a long story about lots of stuff"
    expect(complaint.desired_outcome).to eq "Life gets better"
    expect(complaint.complaint_area.name).to eq 'Special Investigations Unit'
    expect(complaint.complained_to_subject_agency).to eq true
    expect(complaint.date_received.to_date).to eq Date.new(Date.today.year, Date.today.month, 16)
    expect(complaint.complaint_subareas.map(&:name)).to match_array ["Delayed action", "CAT", "Unreasonable delay"]
    expect(complaint.current_assignee_name).to eq User.staff.first.first_last_name
    expect(complaint.status_changes.count).to eq 1
    expect(complaint.status_changes.first.complaint_status.name).to eq "Under Evaluation"
    expect(complaint.agencies.map(&:name)).to include "SAA"
    expect(complaint.agencies.map(&:name)).to include "ACC"
    expect(complaint.complaint_documents.count).to eq 1
    expect(complaint.complaint_documents[0].original_filename).to eq "first_upload_file.pdf"
    expect(complaint.complaint_documents[0].title).to eq "Complaint Document"

    ## on the client
    expect(page_heading).to eq "Complaint, case reference: #{next_ref}"
    expect(find('#complaint #complaint_type').text).to eq "Organization complaint"
    expect(find('#complaint #title').text).to eq "Ambassador"
    expect(find('#complaint #contact_last_name').text).to eq "Normal"
    expect(find('#complaint #contact_first_name').text).to eq "Norman"
    expect(find('#complaint #physical_address').text).to eq "1311 Santa Rosa Avenue"
    expect(find('#complaint #postal_address').text).to eq  "8844 Sebastopol Road"
    expect(find('#complaint #city').text).to eq "Normaltown"
    expect(find('#complaint #province').text).to eq 'Gondwanaland'
    expect(find('#complaint #postal_code').text).to eq '12345'
    expect(find('#complaint #email').text).to eq "norm@acme.co.ws"
    expect(find('#complaint #home_phone').text).to eq "555-1212"
    expect(find('#complaint #cell_phone').text).to eq "555-1212"
    expect(find('#complaint #fax').text).to eq "832-4489"
    expect(find('#complaint #organization_name').text).to eq "Acme Corp"
    expect(find('#complaint #organization_registration_number').text).to eq "1234abcd"
    expect(find('#complaint #preferred_means').text).to eq 'fax'
    expect(find('#complaint #complaint_details').text).to eq "a long story about lots of stuff"
    expect(find('#complaint #desired_outcome').text).to eq "Life gets better"
    expect(find('#complaint #complained_to_subject_agency').text).to eq "yes"
    expect(find('#complaint #date').text).to eq Date.new(Date.today.year, Date.today.month, 16).strftime("%b %-e, %Y")
    expect(find('#complaint #current_assignee').text).to eq user.first_last_name
    expect(find('#complaint #status_changes .status_change .status_humanized').text).to eq 'Under Evaluation'
    #expect(find('#complaint .gender').text).to eq "male" # this should work, but I postponed troubleshooting in favour of other activities!

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

    expect(page.find('#complaint_area').text).to match /Special Investigations Unit/

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
    expect( page_heading ).to eq "Organization Complaint Intake"
    page.go_forward
    expect(page_heading).to eq "Complaint, case reference: #{next_ref}"
    page.go_back
    expect( page_heading ).to eq "Organization Complaint Intake"
    complete_required_fields(:organization)
    next_ref = Complaint.next_case_reference # capture the expected value before saving
    expect{save_complaint}.to change{ Complaint.count }.by(1)
    expect(page_heading).to eq "Complaint, case reference: #{next_ref}"
  end

  it "does not add a new complaint that is invalid" do
    save_complaint(false)
    expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).to have_selector('#city_error', :text => 'You must enter a city')
    expect(page).to have_selector('#province_error', :text => 'You must enter a province')
    expect(page).to have_selector('#postal_code_error', :text => 'You must enter a postal code')
    expect(page).to have_selector('#new_assignee_id_error', :text => 'You must designate an assignee')
    expect(page).to have_selector('#complaint_area_id_error', :text => 'You must select an area')
    expect(page).to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    expect(page).to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).to have_selector('#preferred_means_error', :text => "You must select a preferred means of communication")
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    expect(page).to have_selector('#province_error', :text => "You must enter a province")
    expect(page).to have_selector('#postal_code_error', :text => "You must enter a postal code")
    fill_in('contact_last_name', :with => "Normal")
    expect(page).not_to have_selector('#lastName_error', :text => "You must enter a first name")
    fill_in('contact_first_name', :with => "Norman")
    expect(page).not_to have_selector('#firstName_error', :text => "You must enter a last name")
    fill_in('city', :with => "Leaden Roding")
    expect(page).not_to have_selector('#city_error', :text => 'You must enter a city')
    fill_in('province', with: 'Gondwanaland')
    expect(page).not_to have_selector('#province_error', :text => "You must enter a province")
    fill_in('postal_code', with: '12345')
    expect(page).not_to have_selector('#postal_code_error', :text => "You must enter a postal code")
    # preferred means --mail
    choose('Mail')
    save_complaint(false)
    expect(page).to have_selector('#postal_address_error', :text => "Mail designated as preferred communication means. You must enter a postal address")
    fill_in("postal_address", with: "some text")
    expect(page).not_to have_selector('#postal_address_error', :text => "Mail designated as preferred communication means. You must enter a postal address")
    fill_in("postal_address", with: "")
    save_complaint(false)
    expect(page).to have_selector('#postal_address_error', :text => "Mail designated as preferred communication means. You must enter a postal address")
    choose("Email")
    expect(page).not_to have_selector('#postal_address_error', :text => "Mail designated as preferred communication means. You must enter a postal address")
    # preferred means --email
    save_complaint(false)
    expect(page).to have_selector('#email_error', :text => "email designated as preferred communication means. You must enter an email")
    choose("Home phone")
    expect(page).not_to have_selector('#email_error', :text => "email designated as preferred communication means. You must enter an email")
    # preferred means --home phone
    save_complaint(false)
    expect(page).to have_selector('#home_phone_error', :text => "Home phone designated as preferred communication means. You must enter a home phone number")
    choose("Cell phone")
    expect(page).not_to have_selector('#home_phone_error', :text => "Home phone designated as preferred communication means. You must enter a home phone number")
    # preferred means --cell phone
    save_complaint(false)
    expect(page).to have_selector('#contact_cell_phone_error', :text => "Cell phone designated as preferred communication means. You must enter a cell phone number")
    choose("Fax")
    expect(page).not_to have_selector('#contact_cell_phone_error', :text => "Cell phone designated as preferred communication means. You must enter a cell phone number")
    # preferred means --fax
    save_complaint(false)
    expect(page).to have_selector('#fax_error', :text => "Fax designated as preferred communication means. You must enter a fax number")
    choose('Mail')
    expect(page).not_to have_selector('#fax_error', :text => "Fax designated as preferred communication means. You must enter a fax number")

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
    visit complaint_register_path('en', 'organization')

    attach_file("complaint_fileinput", upload_image)
    expect(page).to have_css('#original_type_error', :text => "File type not allowed")

    expect{ save_complaint }.not_to change{ Complaint.count }
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "sets date_received to today's date if it is not provided when adding" do
    complete_required_fields(:organization)
    expect{save_complaint}.to change{ Complaint.count }.by(1)

    # on the server
    complaint = Complaint.last
    expect(complaint.date_received.to_date).to eq Date.today

    # on the client
    expect(page.find('.date_received').text).to eq Date.today.strftime("%b %-e, %Y")
  end
end
