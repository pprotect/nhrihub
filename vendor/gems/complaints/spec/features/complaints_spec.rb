require 'rails_helper'
$:.unshift File.expand_path '../../helpers', __FILE__
require 'login_helpers'
require 'download_helpers'
require 'complaints_spec_setup_helpers'
require 'navigation_helpers'
require 'complaints_spec_helpers'
require 'upload_file_helpers'
require 'complaints_context_notes_spec_helpers'
require 'complaints_communications_spec_helpers'
require 'active_storage_helpers'

feature "complaints index", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers

  before do
    populate_database
    visit complaints_path('en')
  end

  it "adds a new complaint that is valid" do
    add_complaint
    complete_required_fields
    expect{save_complaint.click; wait_for_ajax}.to change{ Complaint.count }.by(1)

    # on the server
    #puts "on server, first status change is:  #{ActiveRecord::Base.connection.execute('select change_date from status_changes').to_a.last["change_date"]}"
    #puts DateTime.now.strftime("%b %e, %Y")
    expect(first_complaint.find('#status_changes .status_change span.date').text).to eq Date.today.strftime("%b %-e, %Y")
  end
end

feature "complaints index with multiple complaints", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before(:context) do
    Webpacker.compile
  end

  before do
    FactoryBot.create(:complaint, :open, :assigned_to => [@user, @staff_user])
    FactoryBot.create(:complaint, :closed, :assigned_to => [@user, @staff_user])
    FactoryBot.create(:complaint, :open, :assigned_to => [@staff_user, @user])
    FactoryBot.create(:complaint, :closed, :assigned_to => [@staff_user, @user])
    visit complaints_path('en')
  end

  it "shows only open complaints assigned to the current user" do
    expect(page.all('#complaints .complaint').length).to eq 1
    expect(page.find('#complaints .complaint .current_assignee').text).to eq @user.first_last_name
    open_dropdown('Select status')
    expect(select_option('Open')[:class]).to include('selected')
  end
end

feature "complaints index", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers
  include UploadFileHelpers
  include DownloadHelpers
  include ActiveStorageHelpers

  before(:context) do
    Webpacker.compile
  end

  before do
    populate_database
    visit complaints_path('en')
  end

  it "populates filter select dropdown selectors" do
    open_dropdown 'Select area'
    Mandate.all.each do |mandate|
      expect(page).to have_selector('#mandate_filter_select li a span', :text => mandate.name)
    end
    page.find('button', :text => 'Select assignee').click
    User.staff.all.each do |user|
      expect(page).to have_selector('#assignee_filter_select li a span', :text => user.first_last_name)
    end
    page.find('button', :text => 'Select agency').click
    Agency.all.each do |agency|
      expect(page).to have_selector('#agency_filter_select li a span', :text => agency.name)
    end
  end

  it "shows a list of complaints" do
    expect(page.find('h1').text).to eq "Complaints"
    expect(page).to have_selector('#complaints .complaint', :count => 1)
    expect(page.all('#complaints .complaint #status_changes .status_change .status_humanized').first.text).to eq "Open"
    open_dropdown('Select status')
    expect{ select_option('Open').click; wait_for_ajax }.to change{ page.all('#complaints .complaint').count }.by(-1)
    expect{ select_option('Closed').click; wait_for_ajax }.to change{ page.all('#complaints .complaint').count }.by(1)
    expect(page.all('#complaints .complaint #status_changes .status_change .status_humanized').first.text).to eq "Closed"

    ## reset the filter to defaults
    clear_filter_fields
    open_dropdown('Select status')
    expect(page).to have_selector("div.select li.selected")

    ## because there was a bug!
    select_option('Open').click #deselect
    expect(page).not_to have_selector("div.select li.selected")
    clear_filter_fields
    open_dropdown('Select status')
    expect(page).to have_selector("div.select li.selected")

    # highlight filters in effect
    expect(page.find('#complaints_controls .labels div', text: 'Status')[:class]).to include('active')
    expect(page.find('#complaints_controls .labels div', text: 'Assignee')[:class]).to include('active')
  end

  it "shows basic information for each complaint" do
    within first_complaint do
      expect(find('.current_assignee').text).to eq Complaint.first.assignees.first.first_last_name
      expect(find('.date_received').text).to eq Complaint.first.date_received.strftime("%b %-e, %Y")
      expect(all('#status_changes .status_change').first.text).to match /#{Complaint.first.status_changes.first.status_humanized}/
      expect(all('#status_changes .status_change .user_name').first.text).to match /#{Complaint.first.status_changes.first.user.first_last_name}/
      expect(all('#status_changes .status_change .date').first.text).to match /#{Complaint.first.status_changes.first.change_date.getlocal.to_date.strftime("%b %-e, %Y")}/
      expect(all('#status_changes .status_change').last.text).to match /#{Complaint.first.status_changes.last.status_humanized}/
      expect(all('#status_changes .status_change .user_name').last.text).to match /#{Complaint.first.status_changes.last.user.first_last_name}/
      expect(all('#status_changes .status_change .date').last.text).to match /#{Complaint.first.status_changes.last.change_date.getlocal.to_date.strftime("%b %-e, %Y")}/
      expect(find('.lastName').text).to eq Complaint.first.lastName
      expect(find('.firstName').text).to eq Complaint.first.firstName
    end
  end

  it "expands each complaint to show additional information" do
    within first_complaint do
      expand
      expect(find('.complainant_village').text).to eq Complaint.first.village
      expect(find('.complainant_phone').text).to eq Complaint.first.phone
      expect(find('.complaint_details').text).to eq Complaint.first.details

      within assignee_history do
        Complaint.first.assigns.map(&:name).each do |name|
          expect(all('.name').map(&:text)).to include name
        end # /do
        Complaint.first.assigns.map(&:date).each do |date|
          expect(all('.date').map(&:text)).to include date
        end # /do
      end # /within

      within status_changes do
        expect(page).to have_selector('.status_change', :count => 2)
        expect(all('.status_change .user_name')[0].text).to eq Complaint.first.status_changes.sort_by(&:change_date).last.user.first_last_name
        expect(all('.status_change .user_name')[1].text).to eq Complaint.first.status_changes.sort_by(&:change_date).first.user.first_last_name
        expect(all('.status_change .date')[0].text).to eq Complaint.first.status_changes[0].change_date.localtime.to_date.strftime("%b %-e, %Y")
        expect(all('.status_change .date')[1].text).to eq Complaint.first.status_changes[1].change_date.localtime.to_date.strftime("%b %-e, %Y")
        expect(all('.status_change .status_humanized')[0].text).to eq "Open"
        expect(all('.status_change .status_humanized')[1].text).to eq "Closed"
      end

      within complaint_documents do
        Complaint.first.complaint_documents.map(&:title).each do |title|
          expect(all('.complaint_document .title').map(&:text)).to include title
        end
      end

      within good_governance_complaint_bases do
        Complaint.first.good_governance_complaint_bases.map(&:name).each do |complaint_basis_name|
          expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
        end
      end

      within human_rights_complaint_bases do
        Complaint.first.human_rights_complaint_bases.map(&:name).each do |complaint_basis_name|
          expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
        end
      end

      within special_investigations_unit_complaint_bases do
        Complaint.first.special_investigations_unit_complaint_bases.map(&:name).each do |complaint_basis_name|
          expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
        end
      end

      expect(find('#mandate').text).to eq "Human Rights"

      within agencies do
        expect(all('.agency').map(&:text)).to include "SAA"
      end

    end # /within first
  end # /it

  it "adds a new complaint that is valid" do
    add_complaint
    within new_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('dob', :with => "08/09/1950")
      fill_in('email', :with => "norm@acme.co.ws")
      fill_in('village', :with => "Normaltown")
      fill_in('phone', :with => "555-1212")
      fill_in('complaint_details', :with => "a long story about lots of stuff")
      fill_in('desired_outcome', :with => "Life gets better")
      fill_in('chiefly_title', :with => "bossman")
      choose('special_investigations_unit')
      select_male_gender
      choose('complained_to_subject_agency_yes')
      check_basis(:good_governance, "Delayed action")
      check_basis(:human_rights, "CAT")
      check_basis(:special_investigations_unit, "Unreasonable delay")
      select(User.where(login: 'admin').first.first_last_name, :from => "assignee")
      check_agency("SAA")
      check_agency("ACC")
      attach_file("complaint_fileinput", upload_document)
      fill_in("attached_document_title", :with => "Complaint Document")
      select_datepicker_date("#date_received",Date.today.year,Date.today.month,16)
    end
    expect(page).to have_selector("#documents .document .filename", :text => "first_upload_file.pdf")

    next_ref = Complaint.next_case_reference
    expect(new_complaint_case_reference).to eq next_ref
    expect{save_complaint.click; wait_for_ajax}.to change{ Complaint.count }.by(1)
                                               .and change{ page.all('.complaint').count }.by(1)
                                               .and change{ page.all('.new_complaint').count }.by(-1)
                                               .and change { ActionMailer::Base.deliveries.count }.by(1)
    # on the server
    complaint = Complaint.last
    expect(complaint.case_reference).to eq next_ref
    expect(complaint.lastName).to eq "Normal"
    expect(complaint.firstName).to eq "Norman"
    expect(complaint.chiefly_title).to eq "bossman"
    expect(complaint.dob).to eq "08/09/1950" # dd/mm/yyyy
    expect(complaint.gender).to eq 'M'
    expect(complaint.email).to eq "norm@acme.co.ws"
    expect(complaint.complained_to_subject_agency).to eq true
    expect(complaint.village).to eq "Normaltown"
    expect(complaint.phone).to eq "555-1212"
    expect(complaint.details).to eq "a long story about lots of stuff"
    expect(complaint.desired_outcome).to eq "Life gets better"
    expect(complaint.mandate.key).to eq 'special_investigations_unit'
    expect(complaint.good_governance_complaint_bases.map(&:name)).to include "Delayed action"
    expect(complaint.human_rights_complaint_bases.map(&:name)).to include "CAT"
    expect(complaint.special_investigations_unit_complaint_bases.map(&:name)).to include "Unreasonable delay"
    expect(complaint.current_assignee_name).to eq User.admin.first.first_last_name
    expect(complaint.status_changes.count).to eq 1
    expect(complaint.status_changes.first.complaint_status.name).to eq "Under Evaluation"
    expect(complaint.agencies.map(&:name)).to include "SAA"
    expect(complaint.agencies.map(&:name)).to include "ACC"
    expect(complaint.complaint_documents.count).to eq 1
    expect(complaint.complaint_documents[0].original_filename).to eq "first_upload_file.pdf"
    expect(complaint.complaint_documents[0].title).to eq "Complaint Document"
    expect(complaint.date_received.to_date).to eq Date.new(Date.today.year, Date.today.month, 16)

    # on the client
    expect(first_complaint.find('.case_reference').text).to eq next_ref
    expect(first_complaint.find('.current_assignee').text).to eq User.admin.first.first_last_name
    expect(first_complaint.find('.lastName').text).to eq "Normal"
    expect(first_complaint.find('.firstName').text).to eq "Norman"
    expect(first_complaint.find('.chiefly_title').text).to eq "bossman"
    expect(first_complaint.find('#status_changes .status_change .status_humanized').text).to eq 'Under Evaluation'
    expand
    expect(first_complaint.find('.complainant_dob').text).to eq "Sep 8, 1950"
    expect(first_complaint.find('.email').text).to eq "norm@acme.co.ws"
    expect(first_complaint.find('.complaint_details').text).to eq "a long story about lots of stuff"
    expect(first_complaint.find('.desired_outcome').text).to eq "Life gets better"
    expect(first_complaint.find('.complainant_village').text).to eq "Normaltown"
    expect(first_complaint.find('.complainant_phone').text).to eq "555-1212"
    #expect(first_complaint.find('.gender').text).to eq "male" # this should work, but I postponed troubleshooting in favour of other activities!
    expect(first_complaint.find('.gender').text).to eq "M"
    expect(first_complaint.find('.complained_to_subject_agency').text).to eq "yes"
    expect(first_complaint.find('.date_received').text).to eq Date.new(Date.today.year, Date.today.month, 16).strftime("%b %-e, %Y")

    within good_governance_complaint_bases do
      Complaint.last.good_governance_complaint_bases.map(&:name).each do |complaint_basis_name|
        expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
      end
    end

    within human_rights_complaint_bases do
      Complaint.last.human_rights_complaint_bases.map(&:name).each do |complaint_basis_name|
        expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
      end
    end

    within special_investigations_unit_complaint_bases do
      Complaint.last.special_investigations_unit_complaint_bases.map(&:name).each do |complaint_basis_name|
        expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
      end
    end

    within agencies do
      expect(all('.agency').map(&:text)).to include "SAA"
      expect(all('.agency').map(&:text)).to include "ACC"
    end

    within complaint_documents do
      expect(page.all('#complaint_documents .complaint_document')[0].find('.filename').text).to eq "first_upload_file.pdf"
      expect(page.all('#complaint_documents .complaint_document')[0].find('.title').text).to eq "Complaint Document"
    end

    expect(page.find('#mandate').text).to match /Special Investigations Unit/
    email = ActionMailer::Base.deliveries.last
    expect( email.subject ).to eq "Notification of complaint assignment"
    lines = Nokogiri::HTML(email.body.to_s).xpath(".//p").map(&:text)
    # lin[0] is addressee
    expect( lines[0] ).to eq User.admin.first.first_last_name
    # complaint url is embedded in the email
    url = Nokogiri::HTML(email.body.to_s).xpath(".//p/a").attr('href').value
    expect( url ).to match (/\/en\/complaints\.html\?case_reference=c#{Date.today.strftime("%y")}-1$/i)
    expect( url ).to match (/^http:\/\/#{SITE_URL}/)
  end

  it "sets date_received to today's date if it is not provided when adding" do
    add_complaint
    within new_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('dob', :with => "08/09/1950")
      fill_in('village', :with => "Normaltown")
      fill_in('complaint_details', :with => "a long story about lots of stuff")
      choose('special_investigations_unit')
      check_basis(:good_governance, "Delayed action")
      select(User.admin.first.first_last_name, :from => "assignee")
    end
    expect{save_complaint.click; wait_for_ajax}.to change{ Complaint.count }.by(1)
                                               .and change{ page.all('.complaint').count }.by(1)
                                               .and change{ page.all('.new_complaint').count }.by(-1)
    # on the server
    complaint = Complaint.last
    expect(complaint.date_received.to_date).to eq Date.today

    # on the client
    expect(first_complaint.find('.date_received').text).to eq Date.today.strftime("%b %-e, %Y")
  end

  it "adds multiple complaints with no interaction" do #b/c there was a bug
    add_complaint
    within new_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('dob', :with => "08/09/1950")
      fill_in('village', :with => "Normaltown")
      fill_in('complaint_details', :with => "a long story about lots of stuff")
      choose('special_investigations_unit')
      check_basis(:good_governance, "Delayed action")
      check_basis(:human_rights, "CAT")
      check_basis(:special_investigations_unit, "Unreasonable delay")
      select(User.admin.first.first_last_name, :from => "assignee")
    end
    expect{save_complaint.click; wait_for_ajax}.to change{ Complaint.count }.by(1)
                                               .and change{ page.all('.complaint').count }.by(1)
                                               .and change{ page.all('.new_complaint').count }.by(-1)
                                               .and change { ActionMailer::Base.deliveries.count }.by(1)
    add_complaint
    expect(page.find('input#dob').value).to be_blank
    expect(page.find('input#special_investigations_unit')).not_to be_checked
    expect(page.find('input#good_governance')).not_to be_checked
  end

  it "adds 15 complaints and increments case reference for each" do #b/c there was a bug
    15.times do |i|
      add_complaint
      within new_complaint do
        fill_in('lastName', :with => "Normal")
        fill_in('firstName', :with => "Norman")
        fill_in('dob', :with => "08/09/1950")
        fill_in('village', :with => "Normaltown")
        fill_in('complaint_details', :with => "a long story about lots of stuff")
        choose('good_governance')
        check_basis(:special_investigations_unit, "Unreasonable delay")
        select(User.admin.first.first_last_name, :from => "assignee")
      end
      expect{save_complaint.click; wait_for_ajax}.to change{ Complaint.count }.by(1)
    end
    year = Date.today.strftime("%y")
    expect(Complaint.pluck(:case_reference)).to eq ["c12-34","c12-42"]+(1..15).map{|i| "C#{year}-#{i}"}
    expect(page.all('.complaint .basic_info .case_reference').map(&:text)).to eq (1..15).map{|i| "C#{year}-#{i}"}.reverse+["c12-34"]
    add_complaint
    expect(page.find('.new_complaint #case_reference').text).to eq "C#{year}-16"
  end

  it "does not add a new complaint that is invalid" do
    add_complaint
    within new_complaint do
      save_complaint.click
      expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
      expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
      expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
      expect(page).to have_selector('#village_error', :text => 'You must enter a village')
      expect(page).to have_selector('#new_assignee_id_error', :text => 'You must designate an assignee')
      expect(page).to have_selector('#mandate_id_error', :text => 'You must select an area')
      expect(page).to have_selector('#complaint_basis_id_count_error', :text => 'You must select at least one subarea')
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
      expect(page).not_to have_selector('#mandate_ids_count_error', :text => 'You must select an area')
      check_basis(:special_investigations_unit, "Unreasonable delay")
      expect(page).not_to have_selector('#complaint_basis_id_count_error', :text => 'You must select at least one subarea')
      fill_in('complaint_details', :with => "random text")
      expect(page).not_to have_selector('#details_error', :text => "You must enter the complaint details")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end
  end

  it "flags as invalid when file attachment exceeds permitted filesize" do
    add_complaint

    within new_complaint do
      attach_file("complaint_fileinput", big_upload_document)
    end
    expect(page).to have_selector('#filesize_error', :text => "File is too large")

    expect{ save_complaint.click; wait_for_ajax }.not_to change{ Complaint.count }
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "flags as invalid when file attachment is unpermitted filetype" do
    SiteConfig["complaint_document.filetypes"]=["doc"]
    visit complaints_path('en')
    add_complaint

    within new_complaint do
      attach_file("complaint_fileinput", upload_image)
    end
    expect(page).to have_css('#original_type_error', :text => "File type not allowed")

    expect{ save_complaint.click; wait_for_ajax }.not_to change{ Complaint.count }
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
  end

  it "cancels adding" do
    add_complaint
    within new_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('village', :with => "Normaltown")
      fill_in('phone', :with => "555-1212")
      choose('special_investigations_unit')
      check_basis(:good_governance, "Delayed action")
      check_basis(:human_rights, "CAT")
      check_basis(:special_investigations_unit, "Unreasonable delay")
      select(User.admin.first.first_last_name, :from => "assignee")
    end
    cancel_add
    expect(page).not_to have_selector('.new_complaint')
    add_complaint
    within new_complaint do
      expect(page.find('#lastName').value).to be_blank
      expect(page.find('#firstName').value).to be_blank
      expect(page.find('#village').value).to be_blank
      expect(page.find('#phone').value).to be_blank
      expect(basis_checkbox(:good_governance, "Delayed action")).not_to be_checked
      expect(basis_checkbox(:human_rights, "CAT")).not_to be_checked
      expect(basis_checkbox(:special_investigations_unit, "Unreasonable delay")).not_to be_checked
    end
  end

  it "changes complaint current status by adding a status_change" do
    edit_complaint # editing the complaint with case_reference C12-34
    within current_status do
      expect(page).to have_checked_field "open" # default result set is open complaints for current user
      choose "closed"
    end
    expect{ edit_save }.to change{ Complaint.first.current_status }.from("Open").to("Closed")
    open_dropdown('Select status')
    select_option('Closed').click
    sleep(0.2) # javascript
    # the complaint we edited is now the last, b/c there's another more recent that is closed
    expect( last_complaint.all('#status_changes .status_change').last.text ).to match "Closed"
    expect( last_complaint.all('#status_changes .date').last.text ).to match /#{Date.today.strftime("%b %-e, %Y")}/
    user = User.find_by(:login => 'admin')
    expect( last_complaint.all('#status_changes .user_name').last.text ).to match /#{user.first_last_name}/
  end

  it "edits a complaint" do
    edit_complaint
    # COMPLAINANT
    within first_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('chiefly_title', :with => "kahunga")
      fill_in('dob', :with => "19/08/1950")
      fill_in('village', :with => "Normaltown")
      fill_in('phone', :with => "555-1212")
      fill_in('complaint_details', :with => "the boy stood on the burning deck")
      fill_in('desired_outcome', :with => "Things are more better")
      choose('complained_to_subject_agency_no')
      # ASSIGNEE
      select(User.admin.last.first_last_name, :from => "assignee")
      # MANDATE
      choose('special_investigations_unit') # originally had human rights mandate
      # BASIS
      uncheck_basis(:good_governance, "Delayed action") # originally had "Delayed action" and "Failure to Act"
      uncheck_basis(:human_rights, "CAT") # originall had "CAT" "ICESCR"
      uncheck_basis(:special_investigations_unit, "Unreasonable delay") #originally had "Unreasonable delay" "Not properly investigated"
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
    end

    expect{ edit_save }.to change{ Complaint.first.lastName }.to("Normal").
                       and change{ Complaint.first.firstName }.to("Norman").
                       and change{ Complaint.first.village }.to("Normaltown").
                       and change{ Complaint.first.phone }.to("555-1212").
                       and change{ Complaint.first.assignees.count }.by(1).
                       and change{ Complaint.first.complaint_documents.count }.by(1).
                       and change{ stored_files_count }.by(1).
                       and change { ActionMailer::Base.deliveries.count }.by(1)

    expect( Complaint.first.chiefly_title ).to eq "kahunga"
    expect( Complaint.first.complained_to_subject_agency ).to eq false
    expect( Complaint.first.dob ).to eq "19/08/1950"
    expect( Complaint.first.details ).to eq "the boy stood on the burning deck"
    expect( Complaint.first.desired_outcome ).to eq "Things are more better"
    expect( Complaint.first.mandate.key ).to eq "special_investigations_unit"
    expect( Complaint.first.good_governance_complaint_bases.count ).to eq 1
    expect( Complaint.first.good_governance_complaint_bases.first.name ).to eq "Failure to act"
    expect( Complaint.first.human_rights_complaint_bases.count ).to eq 1
    expect( Complaint.first.human_rights_complaint_bases.first.name ).to eq "ICESCR"
    expect( Complaint.first.special_investigations_unit_complaint_bases.count ).to eq 1
    expect( Complaint.first.special_investigations_unit_complaint_bases.first.name ).to eq "Not properly investigated"
    expect( Complaint.first.assignees ).to include User.admin.last
    expect( Complaint.first.agencies.map(&:name) ).to include "MAF"
    expect( Complaint.first.agencies.count ).to eq 1
    expect( Complaint.first.date_received.to_date).to eq Date.new(Date.today.year, Date.today.month, 23)

    expect(page).to have_selector('.complainant_dob', :text => "Aug 19, 1950")
    expect(page).to have_selector('.desired_outcome', :text => "Things are more better")
    expect(page).to have_selector('.complaint_details', :text => "the boy stood on the burning deck")
    expect(page).to have_selector('.complained_to_subject_agency', :text => "no")
    expect(page).to have_selector('.date_received',:text => Date.new(Date.today.year, Date.today.month, 23).strftime("%b %-e, %Y"))

    within good_governance_complaint_bases do
      Complaint.first.good_governance_complaint_bases.map(&:name).each do |complaint_basis_name|
        expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
      end
    end

    within human_rights_complaint_bases do
      Complaint.first.human_rights_complaint_bases.map(&:name).each do |complaint_basis_name|
        expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
      end
    end

    within special_investigations_unit_complaint_bases do
      Complaint.first.special_investigations_unit_complaint_bases.map(&:name).each do |complaint_basis_name|
        expect(page).to have_selector('.complaint_basis', :text => complaint_basis_name)
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

    email = ActionMailer::Base.deliveries.last
    expect( email.subject ).to eq "Notification of complaint assignment"
    lines = Nokogiri::HTML(email.body.to_s).xpath(".//p").map(&:text)
    # lin[0] is addressee
    expect( lines[0] ).to eq User.admin.last.first_last_name
    # complaint url is embedded in the email
    url = Nokogiri::HTML(email.body.to_s).xpath(".//p/a").attr('href').value
    expect( url ).to match (/\/en\/complaints\.html\?case_reference=#{Complaint.first.case_reference}$/)
    expect( url ).to match (/^http:\/\/#{SITE_URL}/)
  end

  it "edits a complaint with no changes to the status" do # b/c there was a bug
    edit_complaint
    expect{ edit_save }.not_to change{ Complaint.first.status_changes.count }
  end

  it "edits a complaint with no change of assignee" do
    edit_complaint
    expect{ edit_save }.to change{ Complaint.first.assignees.count }.by(0)
                       .and change { ActionMailer::Base.deliveries.count }.by(0)
  end

  it "edits a complaint, deleting a file" do
    edit_complaint
    expect(page).to have_selector(".complaint .row.collapse.in", :count => 13) # make sure expanded info is fully rendered before proceeding with the deletion
    expect{delete_document; confirm_deletion; wait_for_ajax}.to change{ Complaint.first.complaint_documents.count }.by(-1).
                                          and change{ documents.count }.by(-1)
  end

  it "should download a complaint document file" do
    sleep(0.2)
    expand
    @doc = ComplaintDocument.first
    filename = @doc.original_filename
    click_the_download_icon
    unless page.driver.instance_of?(Capybara::Selenium::Driver) # response_headers not supported
      expect(page.response_headers['Content-Type']).to eq('application/pdf')
      expect(page.response_headers['Content-Disposition']).to eq("attachment; filename=\"#{filename}\"")
    end
    expect(downloaded_file).to eq filename
  end

  it "restores previous values when editing is cancelled" do
    new_assignee_id = page.evaluate_script("complaints.findAllComponents('complaint')[0].get('new_assignee_id')")
    original_complaint = Complaint.first
    edit_complaint
    expect(page).to have_selector(".complaint .row.collapse.in", :count => 13) # make sure expanded info is fully rendered before proceeding
    within first_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('chiefly_title', :with => "barista")
      fill_in('village', :with => "Normaltown")
      fill_in('phone', :with => "555-1212")
      check_basis(:good_governance, "Private")
      check_basis(:good_governance, "Contrary to Law")
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
    end
    edit_cancel
    sleep(0.5) # seems like a huge amount of time to wait for javascript, but this is what it takes for reliable operation in chrome
    edit_complaint
    expect(page).to have_selector(".complaint .row.collapse.in", :count => 13) # make sure expanded info is fully rendered before proceeding
    within first_complaint do
      expect(page.find('#lastName').value).to eq original_complaint.lastName
      expect(page.find('#firstName').value).to eq original_complaint.firstName
      expect(page.find('#chiefly_title').value).to eq original_complaint.chiefly_title
      expect(page.find('#village').value).to eq original_complaint.village
      expect(page.find('#phone').value).to eq original_complaint.phone
      expect(page.find('#good_governance_bases .complaint_basis', :text => 'Private').find('input')).not_to be_checked
      expect(page.find('#good_governance_bases .complaint_basis', :text => 'Contrary to Law').find('input')).not_to be_checked
      expect(page.find('#human_rights_bases .complaint_basis', :text => 'CAT').find('input')).to be_checked
      expect(page.find('#human_rights_bases .complaint_basis', :text => 'ICESCR').find('input')).to be_checked
      expect(page.find('#special_investigations_unit_bases .complaint_basis', :text => 'Unreasonable delay').find('input')).to be_checked
      expect(page.find('#special_investigations_unit_bases .complaint_basis', :text => 'Not properly investigated').find('input')).to be_checked
      expect(page.find('#good_governance_bases .complaint_basis', :text => 'Delayed action').find('input')).to be_checked
      expect(page.find('#good_governance_bases .complaint_basis', :text => 'Failure to act').find('input')).to be_checked
      expect(page.find('#dob').value).to eq original_complaint.dob
      expect(page.find('#email').value).to eq original_complaint.email.to_s
      expect(page.find('#m')).not_to be_checked
      expect(page.find('#complaint_details').value).to eq original_complaint.details
      expect(page.find('#desired_outcome').value).to eq original_complaint.desired_outcome.to_s
      expect(page.find('#complained_to_subject_agency_yes')).not_to be_checked
      expect(find('#date_received').value).to eq original_complaint.date_received.strftime("%b %-e, %Y")
      new_assignee_id = page.evaluate_script("complaints.findAllComponents('complaint')[0].get('new_assignee_id')")
      expect(new_assignee_id).to be_zero
      expect(find('.current_assignee').text).to eq original_complaint.assignees.first.first_last_name
      expect(page.find(".mandate ##{original_complaint.mandate.key}")).to be_checked
      expect(page.find_field("ACC")).not_to be_checked
      expect(page.find_field("SAA")).to be_checked
      expect(page).not_to have_selector("#attached_document_title")
      expect(page).not_to have_selector(".title .filename")
    end
  end

  it "resets errors if editing is cancelled" do
    edit_complaint
    # COMPLAINANT
    within first_complaint do
      fill_in('lastName', :with => "")
      fill_in('firstName', :with => "")
      fill_in('village', :with => "")
      fill_in('phone', :with => "555-1212")
      fill_in('dob', :with => "")
      fill_in('complaint_details', :with => "")
      # MANDATE
      choose('special_investigations_unit') # originally had human rights mandate
      # BASIS
      uncheck_basis(:good_governance, "Delayed action") # originally had "Delayed action" and "Failure to Act"
      uncheck_basis(:good_governance, "Failure to act") # originally had "Delayed action" and "Failure to Act"
      uncheck_basis(:human_rights, "CAT") # originall had "CAT" "ICESCR"
      uncheck_basis(:human_rights, "ICESCR") # originall had "CAT" "ICESCR"
      uncheck_basis(:special_investigations_unit, "Unreasonable delay") #originally had "Unreasonable delay" "Not properly investigated"
      uncheck_basis(:special_investigations_unit, "Not properly investigated") #originally had "Unreasonable delay" "Not properly investigated"
      # AGENCY
      uncheck_agency("SAA")
    end
    expect{ edit_save }.not_to change{ Complaint.first}

    expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).to have_selector('#village_error', :text => 'You must enter a village')
    expect(page).to have_selector('#complaint_basis_id_count_error', :text => 'You must select at least one subarea')
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")

    edit_cancel
    sleep(0.5) # seems like a huge amount of time to wait for javascript, but this is what it takes for reliable operation in chrome
    edit_complaint
    within first_complaint do
      expect(page).not_to have_selector('#firstName_error', :text => "You must enter a first name")
      expect(page).not_to have_selector('#lastName_error', :text => "You must enter a last name")
      expect(page).not_to have_selector('#village_error', :text => 'You must enter a village')
      expect(page).not_to have_selector('#mandate_name_error', :text => 'You must select an area')
      expect(page).not_to have_selector('#complaint_basis_id_count_error', :text => 'You must select at least one subarea')
      expect(page).not_to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
      expect(page).not_to have_selector('#details_error', :text => "You must enter the complaint details")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end
  end

  it "permits only one add at a time" do
    add_complaint
    add_complaint
    expect(page.all('.new_complaint').count).to eq 1
  end

  it "permits only one edit at a time" do
    FactoryBot.create(:complaint, :open, :assigned_to=>[@user, @staff_user])
    visit complaints_path('en')
    edit_first_complaint
    edit_second_complaint
    expect(page.evaluate_script("_.chain(complaints.findAllComponents('complaint')).map(function(c){return c.get('editing')}).filter(function(c){return c}).value().length")).to eq 1
  end

  it "terminates adding new complaint when editing is inititated" do
    add_complaint
    edit_first_complaint
    expect(page.all('.new_complaint').count).to eq 0
    add_complaint
    within new_complaint do
      expect(page.find('#lastName').value).to be_blank
      expect(page.find('#firstName').value).to be_blank
      expect(page.find('#village').value).to be_blank
      expect(page.find('#phone').value).to be_blank
    end
  end

  it "terminates editing complaint when adding is initiated" do
    original_complaint = Complaint.first
    edit_first_complaint
    within first_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('village', :with => "Normaltown")
      fill_in('phone', :with => "555-1212")
    end
    add_complaint
    expect(page.evaluate_script("_.chain(complaints.findAllComponents('complaint')).map(function(c){return c.get('editing')}).filter(function(c){return c}).value().length")).to eq 0
    cancel_add
    sleep(0.5) # seems like a huge amount of time to wait for javascript, but this is what it takes for reliable operation in chrome
    edit_first_complaint
    within first_complaint do
      expect(page.find('#lastName').value).to eq original_complaint.lastName
      expect(page.find('#firstName').value).to eq original_complaint.firstName
      expect(page.find('#village').value).to eq original_complaint.village
      expect(page.find('#phone').value).to eq original_complaint.phone
    end
  end

  it "deletes a complaint" do
    expect{delete_complaint; confirm_deletion; wait_for_ajax}.to change{ Complaint.count }.by(-1).
                                           and change{ complaints.count }.by(-1)
  end

  it "edits a complaint to invalid values" do
    edit_complaint
    # COMPLAINANT
    within first_complaint do
      fill_in('lastName', :with => "")
      fill_in('firstName', :with => "")
      fill_in('village', :with => "")
      fill_in('phone', :with => "555-1212")
      fill_in('dob', :with => "")
      fill_in('complaint_details', :with => "")
      # BASIS
      uncheck_basis(:good_governance, "Delayed action") # originally had "Delayed action" and "Failure to Act"
      uncheck_basis(:good_governance, "Failure to act") # originally had "Delayed action" and "Failure to Act"
      uncheck_basis(:human_rights, "CAT") # originall had "CAT" "ICESCR"
      uncheck_basis(:human_rights, "ICESCR") # originall had "CAT" "ICESCR"
      uncheck_basis(:special_investigations_unit, "Unreasonable delay") #originally had "Unreasonable delay" "Not properly investigated"
      uncheck_basis(:special_investigations_unit, "Not properly investigated") #originally had "Unreasonable delay" "Not properly investigated"
      # AGENCY
      uncheck_agency("SAA")
    end
    expect{ edit_save }.not_to change{ Complaint.first}

    expect(page).to have_selector('#firstName_error', :text => "You must enter a first name")
    expect(page).to have_selector('#lastName_error', :text => "You must enter a last name")
    expect(page).to have_selector('#village_error', :text => 'You must enter a village')
    expect(page).to have_selector('#complaint_basis_id_count_error', :text => 'You must select at least one subarea')
    expect(page).to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
    expect(page).to have_selector('#details_error', :text => "You must enter the complaint details")
    expect(page).to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    within first_complaint do
      fill_in('lastName', :with => "Normal")
      expect(page).not_to have_selector('#lastName_error', :text => "You must enter a last name")
      fill_in('firstName', :with => "Norman")
      expect(page).not_to have_selector('#firstName_error', :text => "You must enter a first name")
      fill_in('village', :with => "Leaden Roding")
      expect(page).not_to have_selector('#village_error', :text => 'You must enter a village')
      choose('special_investigations_unit')
      expect(page).not_to have_selector('#mandate_id_error', :text => 'You must select an area')
      check_basis(:special_investigations_unit, "Unreasonable delay")
      expect(page).not_to have_selector('#complaint_basis_id_count_error', :text => 'You must select at least one subarea')
      fill_in('dob', :with => "1950/08/19")
      expect(page).not_to have_selector('#dob_error', :text => "You must enter the complainant's date of birth with format dd/mm/yyyy")
      fill_in('complaint_details', :with => "bish bash bosh")
      expect(page).not_to have_selector('#details_error', :text => "You must enter the complaint details")
      expect(page).not_to have_selector('#complaint_error', :text => "Form has errors, cannot be saved")
    end
  end

  it "shows a single complaint when a case_reference query string is appended to the url" do
    create_complaints # 3 complaints
    url = URI(@complaint.index_url)
    visit @complaint.index_url.gsub(%r{.*#{url.host}},'') # hack, don't know how else to do it, host otherwise is SITE_URL defined in lib/constants
    expect(complaints.count).to eq 1
    expect(page.find('#complaints_controls #case_reference').value).to eq @complaint.case_reference
    clear_filter_fields
    expect(complaints.count).to eq 4
    expect(query_string).to be_blank
    #click_back_button
    #expect(page.evaluate_script("window.location.search")).to eq "?case_reference=#{@complaint.case_reference}"
    #expect(complaints.count).to eq 1
  end
end

feature "complaints cache expiration", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers

  before(:context) do
    Webpacker.compile
  end

  feature "expiration by reminder" do
    include ComplaintsRemindersSetupHelpers

    scenario "add a reminder" do
      add_a_reminder
      expect(reminders_icon['data-count']).to eq "2"
      visit complaints_path('en')
      expect(reminders_icon['data-count']).to eq "2" # if cached complaint is rendered, this will still be "1"
    end

    scenario "edit a reminder" do
      expect(page).to have_selector("#reminders .reminder .text", :text => "don't forget the fruit gums mum")
      edit_reminder_icon.click
      select("one-time", :from => :reminder_reminder_type)
      select_date("Dec 31 #{Date.today.year}", :from => :reminder_start_date)
      select(User.first.first_last_name, :from => :reminder_user_id)
      fill_in(:reminder_text, :with => "have a nice day")
      edit_reminder_save_icon.click
      wait_for_ajax

      visit complaints_path('en')
      open_reminders_panel
      expect(page.find("#reminders .reminder .text .in").text).to eq "have a nice day"
    end
  end

  feature "expiration by note" do
    include ComplaintsContextNotesSpecHelpers

    scenario "add a note" do
      add_a_note
      expect(notes_icon['data-count']).to eq "3"
      visit complaints_path('en')
      expect(notes_icon['data-count']).to eq "3"
    end

    scenario "edit a note" do
      edit_note.first.click
      fill_in('note_text', :with => "carpe diem")
      save_edit.click
      wait_for_ajax

      visit complaints_path('en')
      open_notes_modal
      expect(page).to have_selector('#notes .note .text .no_edit span', :text => 'carpe diem')
    end
  end

  feature "expiration by communication" do
    include ComplaintsCommunicationsSpecHelpers
    scenario "add a communication" do
      add_a_communication
      expect(communication_icon['data-count']).to eq "2"
      visit complaints_path('en')
      expect(communication_icon['data-count']).to eq "2"
    end

    scenario "delete a communication" do
      delete_a_communication
      expect(communication_icon['data-count']).to eq "0"
      visit complaints_path('en')
      expect(communication_icon['data-count']).to eq "0"
    end
  end
end

feature "reloads complaints if a different assignee is selected", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers

  before do
    populate_database
    user = FactoryBot.create(:user, firstName: "Norman", lastName: "Normal")
    @norms_complaint = FactoryBot.create(:complaint, :under_evaluation, assigned_to: user)
    visit complaints_path('en')
  end

  it "should show the complaints assigned to the checked assignee" do
    select_assignee('Norman Normal')
    wait_for_ajax
    expect(complaints.count).to eq 1
    expect(first_complaint.find('.case_reference').text).to eq @norms_complaint.case_reference
  end

  it "should show complaints for the current user after alternative assignee setting is cleared" do
    select_assignee('Norman Normal')
    wait_for_ajax
    clear_filter_fields
    wait_for_ajax
    expect(complaints.count).to eq 1
    expected_complaint = Complaint.with_status(:open).for_assignee(User.first).first
    expect(first_complaint.find('.case_reference').text).to eq expected_complaint.case_reference
  end
end

feature "selects complaints by partial match of case reference", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    15.times do
      # case_refs are Cyy-1 .. Cyy-15
      FactoryBot.create(:complaint, :open, assigned_to: User.first, case_reference: Complaint.next_case_reference)
    end
    visit complaints_path(:en)
  end

  # in the tests below we set ractive values directly b/c setting the
  # input values results in many ajax requests
  it "should return partial matches when at least two digits are entered" do
    year = Date.today.strftime('%y') 
    script = "complaints.set('filter_criteria.case_reference','C')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 15
    script = "complaints.set('filter_criteria.case_reference','C#{year[0]}')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 15
    script = "complaints.set('filter_criteria.case_reference','C#{year}')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 15
    script = "complaints.set('filter_criteria.case_reference','C#{year}-1')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 7
    script = "complaints.set('filter_criteria.case_reference','C#{year}-12')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 1
  end

  it "should return partial matches when 3 or 4 digits are entered" do
    year = Date.today.strftime('%y') 
    script = "complaints.set('filter_criteria.case_reference','#{year}1')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 7
    script = "complaints.set('filter_criteria.case_reference','#{year}15')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 1
    script = "complaints.set('filter_criteria.case_reference','#{year}16')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 0
    clear_filter_fields
    wait_for_ajax
    expect(complaints.count).to eq 15
  end

  it "should return a single result when the exact case ref is entered, case insensitive" do
    year = Date.today.strftime('%y') 
    #page.find('input#case_reference').set("c#{year}-10")
    script = "complaints.set('filter_criteria.case_reference','c#{year}-10')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 1
    script = "complaints.set('filter_criteria.case_reference','C#{year}-10')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 1
  end
end

feature "selects complaints by partial match of complainant", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    FactoryBot.create(:complaint, :open, assigned_to: User.first, firstName: "Harry", lastName: "Harker")
    FactoryBot.create(:complaint, :open, assigned_to: User.first, firstName: "Harriet", lastName: "Harker")
    FactoryBot.create(:complaint, :open, assigned_to: User.first, firstName: "Adolph", lastName: "Champlin")
    FactoryBot.create(:complaint, :open, assigned_to: User.first, firstName: "Dawn", lastName: "Mills")
    visit complaints_path(:en)
  end

  # in the tests below we set ractive values directly b/c setting the
  # input values results in many ajax requests
  it "should return partial matches when at least two digits are entered" do
    expect(complaints.count).to eq 4
    script = "complaints.set('filter_criteria.complainant','h')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 3
    script = "complaints.set('filter_criteria.complainant','ha')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 3
    script = "complaints.set('filter_criteria.complainant','harr')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 2
    script = "complaints.set('filter_criteria.complainant','harry')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 1
    clear_filter_fields
    wait_for_ajax
    expect(complaints.count).to eq 4
    script = "complaints.set('filter_criteria.complainant','Mil')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 1
  end
end

feature "selects complaints by match of date ranges", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    FactoryBot.create(:complaint, :open, assigned_to: User.first, date_received: 1.month.ago)
    FactoryBot.create(:complaint, :open, assigned_to: User.first, date_received: 2.months.ago)
    FactoryBot.create(:complaint, :open, assigned_to: User.first, date_received: 3.months.ago)
    FactoryBot.create(:complaint, :open, assigned_to: User.first, date_received: 4.months.ago)
    visit complaints_path(:en)
  end

  it "should return complaints created since the 'since' date" do
    expect(complaints.count).to eq 4
    d = Date.today.advance(months: -3)
    select_datepicker_date('#from',d.year,d.month,d.day)
    wait_for_ajax
    expect(complaints.count).to eq 3
  end

  it "should return complaints created before the 'to' date" do
    expect(complaints.count).to eq 4
    d = Date.today.advance(months: -2)
    select_datepicker_date('#to',d.year,d.month,d.day)
    wait_for_ajax
    expect(complaints.count).to eq 3
  end

  it "should return complaints created within the date range" do
    expect(complaints.count).to eq 4

    d = Date.today.advance(months: -3)
    select_datepicker_date('#from',d.year,d.month,d.day)
    wait_for_ajax
    expect(complaints.count).to eq 3

    d = Date.today.advance(months: -2)
    select_datepicker_date('#to',d.year,d.month,d.day)

    wait_for_ajax
    expect(complaints.count).to eq 2
  end
end

feature "selects complaints by partial match of village", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    FactoryBot.create(:complaint, :open, assigned_to: User.first, village: 'Newtown')
    FactoryBot.create(:complaint, :open, assigned_to: User.first, village: 'Someplace')
    FactoryBot.create(:complaint, :open, assigned_to: User.first, village: 'Amityville')
    FactoryBot.create(:complaint, :open, assigned_to: User.first, village: 'Sebastopol')
    visit complaints_path(:en)
  end

  it "should return complaints with partial match for village" do
    expect(complaints.count).to eq 4
    script = "complaints.set('filter_criteria.village','s')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 2

    script = "complaints.set('filter_criteria.village','st')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 1

    clear_filter_fields
    expect(complaints.count).to eq 4
  end
end

feature "selects complaints by partial match of phone", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    FactoryBot.create(:complaint, :open, assigned_to: User.first, phone: '1284235660ext99')
    FactoryBot.create(:complaint, :open, assigned_to: User.first, phone: '312988622x34')
    FactoryBot.create(:complaint, :open, assigned_to: User.first, phone: 'high3235')
    FactoryBot.create(:complaint, :open, assigned_to: User.first, phone: '432')
    visit complaints_path(:en)
  end

  it "should return complaints with partial match to phone" do
    expect(complaints.count).to eq 4

    script = "complaints.set('filter_criteria.phone','9')"
    page.execute_script(script)
    wait_for_ajax
    expect(complaints.count).to eq 2

    clear_filter_fields
    expect(complaints.count).to eq 4
  end
end

feature "selects complaints by partial match of area", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    FactoryBot.create(:mandate, key: 'strategic_plan')
    FactoryBot.create(:mandate, key: 'good_governance')
    FactoryBot.create(:mandate, key: 'human_rights')
    FactoryBot.create(:mandate, key: 'special_investigations_unit')
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    visit complaints_path(:en)
  end

  it "should return complaints matching the selected areas" do
    open_dropdown 'Select area'
    Mandate.all.each do |mandate|
      expect(page).to have_selector('#mandate_filter_select li.selected a span', :text => mandate.name)
    end
    expect(complaints.count).to eq 4
  end
end

feature "selects complaints matching the selected subarea", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    FactoryBot.create(:complaint, :open, assigned_to: User.first)
    visit complaints_path(:en)
  end

  it "should return complaints created since the 'since' date" do
    expect(1).to eq 0
  end
end
