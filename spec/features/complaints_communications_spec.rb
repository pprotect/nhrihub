require 'rails_helper'
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'navigation_helpers'
require 'complaints_spec_helpers'
require 'complaints_communications_spec_helpers'

feature "complaints communications", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers
  include ComplaintsCommunicationsSpecHelpers

  before do
    populate_database
    visit complaints_path('en')
    open_communications_modal
  end

  it "should show a list of communicaitons" do
    expect(page).to have_selector('#communications_modal')
    expect(page).to have_selector('#communications_modal #communications .communication', :count=>1)
  end

  it "should add a communication" do
    add_communication
    expect(page).to have_selector('#new_communication')
    within new_communication do
      choose("Email")
      find('#communication_date').set('2016, Aug 19')
      close_datepicker
      choose("Received")
      select("Hailee Ortiz", :from => "communication_by")
      fill_in("note", :with => "Some note text")
    end
    expect{ save_communication; wait_for_ajax }.to change{ Communication.count }.by(1).
                                               and change{ communications.count }.by(1)
    # on the server
    communication = Communication.last
    expect(communication.mode).to eq "email"
    expect(communication.date).to eq DateTime.new(2016,8,19,0,0,0,'-7')
    expect(communication.direction).to eq "received"
    expect(communication.user.first_last_name).to eq "Hailee Ortiz"
    expect(communication.note).to eq "Some note text"

    # on the browser
    communication = page.all('#communications .communication')[1]
    within communication do
      expect(find('.date').text).to eq "2016, Aug 19"
      expect(find('.by').text).to eq "Hailee Ortiz"
    end
  end

  it "should validate and not add invalid communication" do
    add_communication
    expect{ save_communication; wait_for_ajax }.not_to change{ Communication.count }
  end

  it "should delete a communication" do
    
  end
end

feature "communications notes", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers

  before do
    populate_database
    visit complaints_path('en')
    open_communications_modal
  end

  it "should add notes to a communication" do
    
  end

  it "should delete notes from a communication" do
    
  end

  it "should edit notes from a communication" do
    
  end
end

feature "communications files", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers

  before do
    populate_database
    visit complaints_path('en')
    open_communications_modal
  end

  it "should add files to a communication" do
    
  end

  it "should delete files from a communication" do
    
  end

  it "should validate file size when adding" do
    
  end

  it "should validae file type when adding" do
    
  end

  it "should download files" do
    
  end
end
