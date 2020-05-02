require 'rails_helper'
require 'login_helpers'
require 'complaints_communications_behaviour'
require 'complaints_list_communications_spec_helpers'

feature "complaints communications", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsListCommunicationsSpecHelpers

  before do
    populate_database(:individual_complaint)
    visit complaints_path('en')
    open_communications_modal
  end

  it_behaves_like "complaint communications"
end
