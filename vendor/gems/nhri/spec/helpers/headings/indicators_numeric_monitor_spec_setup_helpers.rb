require 'rspec/core/shared_context'

module IndicatorsNumericMonitorSpecSetupHelpers
  extend RSpec::Core::SharedContext

  before do
    FactoryBot.create(:heading)
    FactoryBot.create(:human_rights_attribute)
    FactoryBot.create(:indicator,
                       :monitor_format => 'numeric',
                       :numeric_monitor_explanation => "Numeric monitor explanation text",
                       :reminders=>[FactoryBot.create(:reminder, :indicator)],
                       :notes => [FactoryBot.create(:note, :indicator, :created_at => 3.days.ago.to_datetime),FactoryBot.create(:note, :indicator, :created_at => 4.days.ago.to_datetime)],
                       :numeric_monitors => [FactoryBot.create(:numeric_monitor, :date => 3.days.ago),FactoryBot.create(:numeric_monitor, :date => 4.days.ago)])
    #resize_browser_window
    visit nhri_heading_path(:en, Nhri::Heading.first.id)
    show_monitors.click
    sleep(0.3) # css transition
  end
end
