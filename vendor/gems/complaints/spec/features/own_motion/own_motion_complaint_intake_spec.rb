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
    expect(page).to have_selector('.nav #compl .dropdown-menu #own_motion', text: 'Own Motion')
  end
end

feature "own motion complaint duplicate check", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include ComplaintsSpecHelpers
  include UploadFileHelpers
  include ActiveStorageHelpers
  include ParseEmailHelpers
  include AreaSubareaCommonHelpers

  let(:complaint1){ Complaint.first }
  let(:complaint2){ Complaint.last }

  before do
    populate_database(:own_motion_complaint)
    visit complaint_intake_path('en', 'own_motion')
  end

  it "should indicate first step duplicate check" do
    expect(page_heading).to eq "Own Motion Complaint Intake: Duplicate Check"
  end

  it "should have fields disabled that are not relevant for duplicate check" do
    disabled_text_fields = %w[date_received title firstName
                              physical_address postal_address city province postal_code
                              home_phone cell_phone fax complaint_details desired_outcome
                              assignee ]


    preferred_means_checkboxes = %w[preferred_means_mail preferred_means_email
                                    preferred_means_home_phone preferred_means_cell_phone
                                    preferred_means_fax]
    complained_checkboxes = %w[complained_to_subject_agency_yes complained_to_subject_agency_no]
    area_checkboxes = %w[good_governance special_investigations_unit human_rights]

    (status_checkboxes +
     preferred_means_checkboxes + complained_checkboxes + area_checkboxes).each do |checkbox|
      expect(page.find("##{checkbox}")[:disabled]).to eq "true"
    end

    disabled_text_fields.each do |input|
      expect(page).to have_css("##{input}[disabled]")
    end

    hidden_fields = %w[complaint_fileinput]
    hidden_fields.each do |input|
      expect(page).to have_css("##{input}[disabled]", visible:false)
    end

    page.all("[id^='agency']").each do |agency_checkbox|
      expect(agency_checkbox[:disabled]).to eq "false"
    end

    page.all("[id^='subarea']").each do |subarea_checkbox|
      expect(subarea_checkbox[:disabled]).to eq "true"
    end

  end

  it "should show duplicates matching the selected agency" do
    check("SAA")
    page.find(".btn#check_dupes").click
    wait_for_ajax
    expect(page).to have_selector('h4.modal-title', text: "Possible duplicates")
    expect(page).to have_selector('#complainant_match_list', text: "no possible duplicates for complainant")
    expect(page).to have_selector('a.possible_duplicate', text: complaint1.case_reference)
    expect(page).to have_selector('a.possible_duplicate', text: complaint2.case_reference)
  end

  it "should permit switch to intake" do
    page.find("#proceed_to_intake").click
    expect(page_heading).to eq "Own Motion Complaint Intake"
  end
end
