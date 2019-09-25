require 'rails_helper'
require 'advisory_council_issues_context_admin_spec_helper'
require 'file_admin_behaviour'
require 'area_subarea_admin'

feature "advisory council issues areas/subareas admin" do
  let(:area_model){ Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea }
  let(:subarea_model){ Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea }
  let(:admin_page){ nhri_admin_path('en') }

  it_behaves_like "area subarea admin"
end

feature "advisory council issues file admin" do
  include AdvisoryCouncilIssuesContextAdminSpecHelper
  it_behaves_like "file admin"
end
