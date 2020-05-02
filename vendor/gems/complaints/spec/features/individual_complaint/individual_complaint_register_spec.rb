require 'rails_helper'
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
    expect(page).to have_selector('.nav #compl .dropdown-menu #individual', text: 'Individual')
  end
end

feature "complaint register after skip dupe check", :js => true do
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
    expect(IndividualComplaint.last.current_event_description).to eq "Registered"
  end
end

feature "complaint register", :js => true do
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
    populate_database(:individual_complaint)
    visit complaint_register_path('en', 'individual')
  end

  it "initiates registration via duplicate complaints check" do
    visit complaint_intake_path('en', 'individual')
    page.find("#proceed_to_intake").click
    expect(page_heading).to eq "Individual Complaint Intake"
    complete_required_fields(:individual)
    expect{save_complaint}.to change{ IndividualComplaint.count }.by(1)
  end

  it "adds a new complaint that is minimally valid" do
    expect( page_heading ).to eq "Individual Complaint Intake"
    complete_required_fields(:individual)
    expect{save_complaint}.to change{ IndividualComplaint.count }.by(1)

    # on the server
    #puts "on server, first status change is:  #{ActiveRecord::Base.connection.execute('select change_date from status_changes').to_a.last["change_date"]}"
    #puts DateTime.now.strftime("%b %e, %Y")
    expect(page.find('#timeline .timeline_event span.date').text).to eq Date.today.strftime("%b %-e, %Y")
  end

  it "adds a new complaint that is valid" do
    user = User.staff.first
    fill_in('title', :with => "Ambassador")
    fill_in('lastName', :with => "Normal")
    fill_in('firstName', :with => "Norman")
    fill_in('dob', :with => "08/09/1950")
    select_male_gender
    choose('SA ID')
    fill_in('id_value', :with => valid_sa_id)
    expect(page).not_to have_selector('#alt_id_other_type', visible: true)
    choose('identify_by_other_id')
    expect(page).to have_selector('#alt_id_other_type')
    fill_in('alt_id_other_type', :with => 'immigration card')
    fill_in('alt_id_value', :with => '1b2b3bc')
    fill_in('physical_address', :with => '1311 Santa Rosa Avenue')
    fill_in('postal_address', :with => '8844 Sebastopol Road')
    fill_in('city', :with => "Normaltown")
    select('Gauteng', from: 'province')
    fill_in('postal_code', with: '12345')
    fill_in('email', :with => "norm@acme.co.ws")
    fill_in('home_phone', :with => "555-1212")
    fill_in('cell_phone', :with => "555-1212")
    fill_in('fax', with: '832-4489')
    choose('Fax')
    fill_in('complaint_details', :with => "a long story about lots of stuff")
    fill_in('desired_outcome', :with => "Life gets better")
    choose('special_investigations_unit')
    choose('complained_to_subject_agency_yes')
    select_datepicker_date("#date_received",Date.today.year,Date.today.month,16)
    check_subarea(:good_governance, "Delayed action")
    check_subarea(:human_rights, "CAT")
    check_subarea(:special_investigations_unit, "Unreasonable delay")
    #select(user.first_last_name, :from => "assignee")
    select_local_municipal_agency("Lesedi")
    attach_file("complaint_fileinput", upload_document)
    fill_in("attached_document_title", :with => "Complaint Document")

    expect(page).to have_selector("#complaint_documents .document .filename", :text => "first_upload_file.pdf")

    expect{save_complaint}.to change{ IndividualComplaint.count }.by(1)
                                .and change{ ComplaintComplaintSubarea.count }.by(3)
                                #.and change{ ActionMailer::Base.deliveries.count }.by(1)
    ## on the server
    complaint = IndividualComplaint.last
    expect(complaint).to be_a(IndividualComplaint)
    expect(complaint.case_reference.year).to eq complaint.case_reference.year
    expect(complaint.case_reference.sequence).to eq 3
    expect(complaint.title).to eq "Ambassador"
    expect(complaint.lastName).to eq "Normal"
    expect(complaint.firstName).to eq "Norman"
    expect(complaint.dob).to eq "08/09/1950" # dd/mm/yyyy
    expect(complaint.gender).to eq 'M'
    expect(complaint.id_type).to eq 'State id'
    expect(complaint.id_value).to eq valid_sa_id.strip.to_i
    expect(complaint.alt_id_type).to eq 'other'
    expect(complaint.alt_id_other_type).to eq 'immigration card'
    expect(complaint.alt_id_value).to eq '1b2b3bc'
    expect(complaint.physical_address).to eq "1311 Santa Rosa Avenue"
    expect(complaint.postal_address).to eq "8844 Sebastopol Road"
    expect(complaint.city).to eq "Normaltown"
    expect(complaint.province.name).to eq "Gauteng"
    expect(complaint.postal_code).to eq "12345"
    expect(complaint.email).to eq "norm@acme.co.ws"
    expect(complaint.home_phone).to eq "555-1212"
    expect(complaint.cell_phone).to eq "555-1212"
    expect(complaint.fax).to eq "832-4489"
    expect(complaint.preferred_means).to eq 'fax'
    expect(complaint.details).to eq "a long story about lots of stuff"
    expect(complaint.desired_outcome).to eq "Life gets better"
    expect(complaint.complaint_area.name).to eq 'Special Investigations Unit'
    expect(complaint.complained_to_subject_agency).to eq true
    expect(complaint.date_received.to_date).to eq Date.new(Date.today.year, Date.today.month, 16)
    expect(complaint.complaint_subareas.map(&:name)).to match_array ["Delayed action", "CAT", "Unreasonable delay"]
    #expect(complaint.current_assignee_name).to eq User.staff.first.first_last_name
    expect(complaint.status_changes.count).to eq 1
    expect(complaint.status_changes.first.complaint_status.name).to eq "Registered"
    expect(complaint.agencies.first.name).to eq 'Lesedi'
    expect(complaint.complaint_documents.count).to eq 1
    expect(complaint.complaint_documents[0].original_filename).to eq "first_upload_file.pdf"
    expect(complaint.complaint_documents[0].title).to eq "Complaint Document"

    ## on the client
    expect(page_heading).to eq "Complaint, case reference: #{Complaint.last.case_reference}"
    expect(find('#complaint #complaint_type').text).to eq "Individual complaint"
    expect(find('#complaint #title').text).to eq "Ambassador"
    expect(find('#complaint #lastName').text).to eq "Normal"
    expect(find('#complaint #firstName').text).to eq "Norman"
    expect(find('#complaint #complainant_dob').text).to eq "08/09/1950"
    expect(find('#complaint #gender').text).to eq "M"
    expect(find('#complaint #id_type').text).to eq "State id"
    expect(find('#complaint #id_value').text).to eq valid_sa_id.strip.to_s
    expect(find('#complaint #alt_id_name').text).to eq 'immigration card'
    expect(find('#complaint #alt_id_value').text).to eq '1b2b3bc'
    expect(find('#complaint #physical_address').text).to eq "1311 Santa Rosa Avenue"
    expect(find('#complaint #postal_address').text).to eq  "8844 Sebastopol Road"
    expect(find('#complaint #city').text).to eq "Normaltown"
    expect(find('#complaint #province').text).to eq 'Gauteng'
    expect(find('#complaint #postal_code').text).to eq '12345'
    expect(find('#complaint #email').text).to eq "norm@acme.co.ws"
    expect(find('#complaint #home_phone').text).to eq "555-1212"
    expect(find('#complaint #cell_phone').text).to eq "555-1212"
    expect(find('#complaint #fax').text).to eq "832-4489"
    expect(find('#complaint #preferred_means').text).to eq 'fax'
    expect(find('#complaint #complaint_details').text).to eq "a long story about lots of stuff"
    expect(find('#complaint #desired_outcome').text).to eq "Life gets better"
    expect(find('#complaint #complained_to_subject_agency').text).to eq "yes"
    expect(find('#complaint #date').text).to eq Date.new(Date.today.year, Date.today.month, 16).strftime(Complaint::DateFormat)
    #expect(find('#complaint #current_assignee').text).to eq user.first_last_name
    expect(find('#complaint #timeline .timeline_event .event_label').text).to eq 'Initial status'
    #expect(find('#complaint .gender').text).to eq "male" # this should work, but I postponed troubleshooting in favour of other activities!

    within special_investigations_unit_area do
      IndividualComplaint.last.complaint_subareas.special_investigations_unit.map(&:name).each do |subarea_name|
        expect(page).to have_selector('.subarea', :text => subarea_name)
      end
    end

    expect(find('.agency').text).to eq "Gauteng province, Sedibeng district, Lesedi municipality"

    within complaint_documents do
      doc = page.all('.complaint_document')[0]
      expect(doc.find('.filename').text).to eq "first_upload_file.pdf"
      expect(doc.find('.title').text).to eq "Complaint Document"
    end

    expect(page.find('#complaint_area').text).to match /Special Investigations Unit/

    # Email notification
    #expect( email.subject ).to eq "Notification of complaint assignment"
    #expect( addressee ).to eq user.first_last_name
    #expect( complaint_url ).to match (/#{Regexp.escape complaint.url}$/i)
    #expect( complaint_url ).to match (/^https:\/\/#{SITE_URL}/)
    #expect( header_field('From')).to eq "NHRI Hub Administrator<no_reply@nhri-hub.com>"
    #expect( header_field('List-Unsubscribe-Post')).to eq "List-Unsubscribe=One-Click"
    #expect( header_field('List-Unsubscribe')).to eq admin_unsubscribe_url(:en,user.id, user.reload.unsubscribe_code, host: SITE_URL, protocol: :https)
    #expect( unsubscribe_url ).to match (/\/en\/admin\/unsubscribe\/#{user.id}\/[0-9a-f]{40}$/) # unsubscribe code

    # back button
    page.go_back
    expect( page_heading ).to eq "Individual Complaint Intake"
    page.go_forward
    expect(page_heading).to eq "Complaint, case reference: #{Complaint.last.case_reference}"
    page.go_back
    expect( page_heading ).to eq "Individual Complaint Intake"
    complete_required_fields(:individual)
    expect{save_complaint}.to change{ IndividualComplaint.count }.by(1)
    expect(page_heading).to eq "Complaint, case reference: #{Complaint.last.case_reference}"
  end

  it "does not add a new complaint that is invalid" do
    save_complaint(false)
    expect(page).to have_selector('#date_received_error', :text => "You must enter date with format dd/mm/yyyy")
    expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).to have_selector('#city_error', :text => 'You must enter a city')
    expect(page).to have_selector('#postal_code_error', :text => 'You must enter a postal code')
    expect(page).to have_selector('#complaint_area_id_error', :text => 'You must select an area')
    expect(page).not_to have_selector('#id_value_error', :text => 'Invalid SA ID') # only when type SA ID is checked
    expect(page).to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    expect(page).to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).to have_selector('#preferred_means_error', :text => "You must select a preferred means of communication")
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    expect(page).to have_selector('#province_error', :text => "You must select a province")
    expect(page).to have_selector('#postal_code_error', :text => "You must enter a postal code")
 
    # date_received
    fill_in('date_received', with: "19/19/1919")
    expect(page).not_to have_selector('#date_received_error')
    save_complaint(false)
    expect(page).to have_selector('#date_received_error', :text => "You must enter date with format dd/mm/yyyy")

    fill_in('date_received', :with => "19/08/1968")
    expect(page).not_to have_selector('#date_received_error')
    # /date_received

   expect(page).to have_selector('#agency_id_error', :text => "You must select an agency")
    fill_in('lastName', :with => "Normal")
    expect(page).not_to have_selector('#lastName_error', :text => "You must enter a first name")
    fill_in('firstName', :with => "Norman")
    expect(page).not_to have_selector('#firstName_error', :text => "You must enter a last name")

    # DOB
    fill_in('dob', with: "19/19/1919")
    expect(page).not_to have_selector('#dob_error')
    save_complaint(false)
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")

    fill_in('dob', :with => "19/08/1968")
    expect(page).not_to have_selector('#dob_error')
    #/ DOB

    expect(page).not_to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    fill_in('city', :with => "Leaden Roding")
    expect(page).not_to have_selector('#city_error', :text => 'You must enter a city')
    select('Gauteng', from: 'province')
    expect(page).not_to have_selector('#province_error', :text => "You must select a province")
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
    expect(page).to have_selector('#cell_phone_error', :text => "Cell phone designated as preferred communication means. You must enter a cell phone number")
    choose("Fax")
    expect(page).not_to have_selector('#cell_phone_error', :text => "Cell phone designated as preferred communication means. You must enter a cell phone number")
    # preferred means --fax
    save_complaint(false)
    expect(page).to have_selector('#fax_error', :text => "Fax designated as preferred communication means. You must enter a fax number")
    choose('Mail')
    expect(page).not_to have_selector('#fax_error', :text => "Fax designated as preferred communication means. You must enter a fax number")
    fill_in("postal_address", with: "some text") # get rid of the mail error

    choose('special_investigations_unit')
    expect(page).not_to have_selector('#complaint_area_id_error', :text => 'You must select an area')
    check_subarea(:special_investigations_unit, "Unreasonable delay")
    expect(page).not_to have_selector('#subarea_id_count_error', :text => 'You must select at least one subarea')
    fill_in('complaint_details', :with => "random text")
    expect(page).not_to have_selector('#details_error', :text => "You must enter the complaint details")
    select_local_municipal_agency("Lesedi")
    expect(page).not_to have_selector('#agency_id_error', :text => "You must select an agency")
    # SA ID validation:
    choose('Passport')
    expect(page).not_to have_selector('#id_value_error', :text => 'Invalid SA ID')
    choose('SA ID')
    save_complaint(false)
    expect(page).to have_selector('#id_value_error', :text => 'Invalid SA ID')
    fill_in('id_value',with: invalid_sa_id) # enter anything removes the error
    expect(page).not_to have_selector('#id_value_error', :text => 'Invalid SA ID')
    save_complaint(false)
    expect(page).to have_selector('#id_value_error', :text => 'Invalid SA ID')
    fill_in('id_value',with: valid_sa_id) # enter anything removes the error
    save_complaint(false)
    expect(page).not_to have_selector('#id_value_error', :text => 'Invalid SA ID')

    expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "flags as invalid when file attachment exceeds permitted filesize" do
    attach_file("complaint_fileinput", big_upload_document)
    expect(page).to have_selector('#filesize_error', :text => "File is too large")

    expect{ save_complaint }.not_to change{ IndividualComplaint.count }
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "flags as invalid when file attachment is unpermitted filetype" do
    SiteConfig["complaint_document.filetypes"]=["doc"]
    visit complaint_register_path('en', 'individual')

    attach_file("complaint_fileinput", upload_image)
    expect(page).to have_css('#original_type_error', :text => "File type not allowed")

    expect{ save_complaint }.not_to change{ IndividualComplaint.count }
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "sets date_received to today's date if it is not provided when adding" do
    complete_required_fields(:individual)
    expect{save_complaint}.to change{ IndividualComplaint.count }.by(1)

    # on the server
    complaint = IndividualComplaint.last
    expect(complaint.date_received.to_date).to eq Time.zone.now.to_date

    # on the client
    expect(page.find('.date_received').text).to eq Time.zone.now.to_date.strftime(Complaint::DateFormat)
  end
end
