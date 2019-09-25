require 'rails_helper'
require 'login_helpers'
require 'project_admin_spec_helpers'
require 'navigation_helpers'
require 'shared_behaviours/file_admin_behaviour'
require 'shared_behaviours/area_subarea_admin'
require 'file_admin_common_helpers'

feature "project file admin", :js => true do
  include ProjectAdminSpecHelpers
  include FileAdminCommonHelpers
  it_should_behave_like 'file admin'
end

feature "project admin", :js => true do
  let(:area_model){ ProjectArea }
  let(:subarea_model){ ProjectSubarea }
  let(:admin_page){ project_admin_path('en') }
  it_behaves_like 'area subarea admin'
end
