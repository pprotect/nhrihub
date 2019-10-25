require 'rspec/core/shared_context'

module ProjectCommonSetupMethods
  extend RSpec::Core::SharedContext

  def populate_mandates
    Mandate::DefaultNames.each do |name|
      Mandate.find_or_create_by(:name => name)
    end
  end

  def populate_types
    gg = ProjectArea.find_or_create_by(:name => 'Good Governance')
    hr = ProjectArea.find_or_create_by(:name => 'Human Rights')

    gg_subareas = [ "Consultation", "Awareness Raising"]
    gg_subareas.each do |type|
      ProjectSubarea.create(:name => type, :area_id => gg.id)
    end

    hr_subareas = ["Schools", "Amicus Curiae", "State of Human Rights Report"]
    hr_subareas.each do |type|
      ProjectSubarea.create(:name => type, :area_id => hr.id)
    end
  end

  def setup_strategic_plan
    sp = StrategicPlan.create(:created_at => 6.months.ago.to_date, :title => "a plan for the millenium")
    spl = StrategicPriority.create(:strategic_plan_id => sp.id, :priority_level => 1, :description => "Gonna do things betta")
    pr = PlannedResult.create(:strategic_priority_id => spl.id, :description => "Something profound")
    o = Outcome.create(:planned_result_id => pr.id, :description => "ultimate enlightenment")
    a1 = Activity.create(:description => "Smarter thinking", :outcome_id => o.id)
    3.times do
      PerformanceIndicator.create(:description => Faker::Lorem.words(3).join(" "), :target => "90%", :activity_id => a1.id)
    end
    a2 = Activity.create(:description => "Public outreach", :outcome_id => o.id)
    3.times do
      PerformanceIndicator.create(:description => Faker::Lorem.words(3).join(" "), :target => "90%", :activity_id => a2.id)
    end
    a3 = Activity.create(:description => "Media coverage", :outcome_id => o.id)
    3.times do
      PerformanceIndicator.create(:description => Faker::Lorem.words(3).join(" "), :target => "90%", :activity_id => a3.id)
    end
  end
end

