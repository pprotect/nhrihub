require 'rspec/core/shared_context'
require 'notes_spec_common_helpers'

module NotesSpecHelpers
  extend RSpec::Core::SharedContext
  include NotesSpecCommonHelpers
  def setup_note
    FactoryBot.create(:note, :notable_type => "Activity", :notable_id => Activity.first.id)
  end
end
