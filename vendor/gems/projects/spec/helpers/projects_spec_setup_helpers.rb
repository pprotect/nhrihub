require 'rspec/core/shared_context'

module ProjectsSpecSetupHelpers
  mattr_accessor :project_count
  extend RSpec::Core::SharedContext
  before do
    setup_strategic_plan
    populate_mandates
    populate_types
    populate_database(context)
    set_file_defaults
    visit projects_path(:en)
  end

  def context
    value =
      case self.class.name
      when /Reminder/
        'reminders'
      when /Notes/
        'notes'
      else
        'project'
      end
    ActiveSupport::StringInquirer.new(value)
  end

  def set_file_defaults
    SiteConfig['project_document.filetypes'] = ['pdf']
    SiteConfig['project_document.filesize'] = 5
  end

  def populate_database(context)
    if context.project?
      # projects_spec needs 2
      FactoryBot.create(:project,
                         :with_documents,
                         :with_performance_indicators)
      @project = FactoryBot.create(:project,
                               :with_named_documents,
                               :with_performance_indicators,
                               :with_mandate,
                               :with_subareas,
                               :title => '" all? the<>\ [] ){} ({)888.,# weird // @;:characters &')
    elsif context.reminders?
      # project_reminders_spec needs 1 project
      @project = FactoryBot.create(:project,
                               :with_named_documents,
                               :with_performance_indicators,
                               :with_mandate,
                               :with_subareas,
                               :title => '" all? the<>\ [] ){} ({)888.,# weird // @;:characters &')
    elsif context.notes?
      FactoryBot.create(:project,
                       :reminders=>[FactoryBot.create(:reminder, :project)],
                       :notes =>   [FactoryBot.create(:note, :project, :created_at => 3.days.ago.to_datetime),FactoryBot.create(:note, :advisory_council_issue, :created_at => 4.days.ago.to_datetime)])
    end
  end


  def populate_mandates
    ["good_governance", "human_rights", "special_investigations_unit", "strategic_plan"].each do |key|
      Mandate.find_or_create_by(:key => key)
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

