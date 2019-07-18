require 'rails_helper'
require 'navigation_helpers'
$:.unshift Nhri::Engine.root.join('spec', 'helpers', 'advisory_council')
require 'terms_of_reference_context_admin_spec_helper'
require 'shared_behaviours/file_admin_behaviour'

feature "terms of reference file admin" do
  include TermsOfReferenceContextAdminSpecHelper
  it_should_behave_like "file admin"
end
