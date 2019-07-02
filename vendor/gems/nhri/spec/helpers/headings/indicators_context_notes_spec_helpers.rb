require 'rspec/core/shared_context'

module IndicatorsContextNotesSpecHelpers
  extend RSpec::Core::SharedContext

  before do
    FactoryBot.create(:heading)
    FactoryBot.create(:human_rights_attribute)
    FactoryBot.create(:indicator,
                       :reminders=>[FactoryBot.create(:reminder, :indicator)],
                       :notes => [FactoryBot.create(:note, :indicator, :created_at => 3.days.ago.to_datetime),FactoryBot.create(:note, :indicator, :created_at => 4.days.ago.to_datetime)])
    #resize_browser_window
    visit nhri_heading_path(:en, Nhri::Heading.first.id)
    page.all('.show_notes')[0].click
    sleep(0.3) # css transition
  end
end
