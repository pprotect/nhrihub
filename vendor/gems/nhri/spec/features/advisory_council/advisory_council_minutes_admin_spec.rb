require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
$:.unshift Nhri::Engine.root.join('spec', 'helpers', 'advisory_council')
require 'advisory_council_minutes_context_admin_spec_helper'
require 'shared_behaviours/file_admin_behaviour'

feature "advisory council minutes admin" do
  include AdvisoryCouncilMinutesContextAdminSpecHelper
  it_should_behave_like "file admin"
end
