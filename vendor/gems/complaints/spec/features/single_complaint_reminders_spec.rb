require 'rails_helper'
$:.unshift File.expand_path '../../helpers', __FILE__
require 'login_helpers'
require 'navigation_helpers'
require 'single_complaint_reminders_setup_helpers'
require 'reminders_behaviour'

feature "show reminders", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include SingleComplaintRemindersSetupHelpers

  it_behaves_like "reminders"
end

