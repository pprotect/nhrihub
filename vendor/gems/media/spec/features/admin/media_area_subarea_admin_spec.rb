require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
require 'media_admin_spec_helpers'
require 'area_subarea_admin'

feature "configure description areas and subareas", :js => true do
  #include MediaAdminSpecHelpers
  let(:area_model){ MediaArea }
  let(:subarea_model){ MediaSubarea }
  let(:admin_page){ media_appearance_admin_path('en') }

  it_behaves_like "area subarea admin"
end
