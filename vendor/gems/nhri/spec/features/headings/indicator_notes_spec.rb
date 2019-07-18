require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
$:.unshift Nhri::Engine.root.join('spec', 'helpers', 'headings')
require 'notes_spec_helpers'
require 'indicators_context_notes_spec_helpers'
require 'notes_behaviour'


feature "indicator notes", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include NotesSpecHelpers
  include IndicatorsContextNotesSpecHelpers
  it_behaves_like "notes"
end
