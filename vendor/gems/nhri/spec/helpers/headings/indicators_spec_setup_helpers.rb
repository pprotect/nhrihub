require 'rspec/core/shared_context'

module IndicatorsSpecSetupHelpers
  extend RSpec::Core::SharedContext
  before do
    heading = FactoryBot.create(:heading)
    attribute = FactoryBot.create(:human_rights_attribute, :description => "First attribute")
    another_attribute = FactoryBot.create(:human_rights_attribute, :description => "Second attribute")
    2.times do
      FactoryBot.create(:indicator,
                         :monitor_format => 'numeric',
                         :human_rights_attribute_id => attribute.id,
                         :nature => 'Structural',
                         :heading_id => heading.id,
                         :numeric_monitor_explanation => 'percentage of dogs that like cats',
                         :reminders=>[FactoryBot.create(:reminder, :indicator)],
                         :notes => [FactoryBot.create(:note, :indicator, :created_at => 3.days.ago.to_datetime)])
    end
    visit nhri_heading_path(:en, Nhri::Heading.first.id)
  end
end
