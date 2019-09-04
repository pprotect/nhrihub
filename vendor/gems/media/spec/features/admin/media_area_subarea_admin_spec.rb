require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
require 'media_admin_spec_helpers'
require 'area_subarea_admin'

feature "configure description areas and subareas", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include MediaAdminSpecHelpers

  it_behaves_like "area subarea admin"
end
