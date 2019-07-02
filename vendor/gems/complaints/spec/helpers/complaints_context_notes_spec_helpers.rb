require 'rspec/core/shared_context'

module ComplaintsContextNotesSpecHelpers
  extend RSpec::Core::SharedContext

  before do
    FactoryBot.create(:complaint,
                       :reminders=>[FactoryBot.create(:reminder, :complaint)],
                       :notes =>   [FactoryBot.create(:note, :complaint, :created_at => 3.days.ago.to_datetime),FactoryBot.create(:note, :advisory_council_issue, :created_at => 4.days.ago.to_datetime)])
    resize_browser_window
    visit complaints_path(:en)
    open_notes_modal
  end
end

