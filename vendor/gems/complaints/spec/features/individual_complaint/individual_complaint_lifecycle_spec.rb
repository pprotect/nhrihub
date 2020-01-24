require 'rails_helper'
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'complaints_spec_helpers'
require 'area_subarea_common_helpers'

feature "complaint register", :js => true do
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
    expect(IndividualComplaint.last.current_status_humanized).to eq "Registered"
  end


end

feature "complaints list", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers

  before do
    FactoryBot.create( :individual_complaint, :registered )
    FactoryBot.create( :individual_complaint, :registered )
    visit complaints_path('en')
  end

  it "should show registered status complaints in the complaints list" do
    expect(page.find('h1').text).to eq "Complaints"
    expect(page).to have_no_selector('#complaints .complaint')
    open_dropdown('Select status')
    expect{ select_option('Registered').click; wait_for_ajax }.to change{ page.all('#complaints .complaint').count }.by(2)

    select_option('Registered').click #deselect
    expect(page).not_to have_selector("div.select li.selected")
    clear_filter_fields
    open_dropdown('Select status')
    expect(page).to have_selector("div.select li.selected", count: 0)
  end
end
