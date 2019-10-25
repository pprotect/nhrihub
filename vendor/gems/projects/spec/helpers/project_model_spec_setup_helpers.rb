require 'rspec/core/shared_context'
require 'project_common_setup_methods.rb'

module ProjectModelSpecSetupHelpers
  extend RSpec::Core::SharedContext
  include ProjectCommonSetupMethods

  before do
    populate_mandates
    populate_types
    setup_strategic_plan
  end

  def promiscuous_query
    {title: "",
     mandate_ids: Mandate.pluck(:id) << 0,
     subarea_ids: ProjectSubarea.pluck(:id) << 0,
     performance_indicator_ids: PerformanceIndicator.pluck(:id)}
  end

end
