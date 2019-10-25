require 'rspec/core/shared_context'
require 'project_common_setup_methods.rb'

module ProjectsSpecSetupHelpers
  mattr_accessor :project_count
  extend RSpec::Core::SharedContext
  include ProjectCommonSetupMethods

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

end

