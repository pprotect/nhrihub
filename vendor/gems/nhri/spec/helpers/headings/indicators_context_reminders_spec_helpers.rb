require 'rspec/core/shared_context'

module IndicatorsContextRemindersSpecHelpers
  extend RSpec::Core::SharedContext

  before do
    FactoryBot.create(:heading)
    FactoryBot.create(:human_rights_attribute)
    FactoryBot.create(:indicator, :with_reminder, :with_notes)
    visit nhri_heading_path(:en, Nhri::Heading.first.id)
    page.all('.alarm_icon')[0].click
    sleep(0.3) # css transition
  end
end
