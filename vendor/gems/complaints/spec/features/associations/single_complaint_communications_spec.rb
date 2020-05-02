require 'rails_helper'
require 'login_helpers'
require 'complaints_communications_behaviour'
require 'single_complaint_communications_spec_helpers'

feature "complaints communications", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include SingleComplaintCommunicationsSpecHelpers

  before do
    populate_database(:individual_complaint)
    visit complaint_path('en',Complaint.first.id)
    open_communications_modal
  end

  it_behaves_like "complaint communications"
end
