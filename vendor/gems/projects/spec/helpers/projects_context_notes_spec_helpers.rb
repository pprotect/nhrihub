require 'rspec/core/shared_context'

module ProjectsContextNotesSpecHelpers
  extend RSpec::Core::SharedContext

  before do
    sp = FactoryBot.create(:project,
                       :reminders=>[FactoryBot.create(:reminder, :project)],
                       :notes =>   [FactoryBot.create(:note, :project, :created_at => 3.days.ago.to_datetime),FactoryBot.create(:note, :advisory_council_issue, :created_at => 4.days.ago.to_datetime)])
    visit projects_path(:en)
    open_notes_modal
  end
end
