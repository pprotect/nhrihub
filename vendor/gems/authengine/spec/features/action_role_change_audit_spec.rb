require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'

feature "complaints index", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include NavigationHelpers

  before do
    visit authengine_action_roles_path(:en)
  end

  it "creates an action_role_change record" do
    expect(page).to have_selector('h1', text: "Configure Permissions for Roles")
    row = page.find('form').find(:xpath, '//tr[descendant::text()[contains(.,"admin/organizations") and contains(.,"index")]]')
    checkboxes = row.all('input[type="checkbox"]')
    checkboxes.first.uncheck
    checkboxes.last.check
    expect{page.find('input[value="Save"]').click}.to change{ActionRoleChange.count}.by(2)
  end
end
