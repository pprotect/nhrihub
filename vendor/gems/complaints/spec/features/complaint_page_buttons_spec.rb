require 'rails_helper'
$:.unshift File.expand_path '../../helpers', __FILE__
require 'login_helpers'
require 'complaints_spec_setup_helpers'
require 'navigation_helpers'
require 'complaints_spec_helpers'

feature "complaint intake and register", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user

  before do
    visit complaint_intake_path('en', 'individual')
  end

  context "complaint intake" do
    it "should have check and proceed enabled, save disabled" do
      test_fail_placeholder
    end
  end

  context "complaint register" do
    it "should have check and save enabled, proceed disabld" do
      test_fail_placeholder
    end
  end
  
end

feature "complaint show and edit", js: true do
  before do
    complaint = FactoryBot.create(:individual_complaint)
    visit complaints_path('en', complaint)
  end

  context "show mode" do
    it "should have no buttons visible" do
      
    end
  end

  context "edit mode" do
    it "should have save and cancel displayed and enabled" do
      
    end
  end
end
