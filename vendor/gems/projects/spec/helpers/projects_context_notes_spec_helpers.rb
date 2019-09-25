require 'rspec/core/shared_context'
require 'projects_spec_setup_helpers'

module ProjectsContextNotesSpecHelpers
  extend RSpec::Core::SharedContext
  include ProjectsSpecSetupHelpers

  before do
    open_notes_modal
  end
end
