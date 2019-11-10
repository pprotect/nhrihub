FactoryBot.define do
  factory :project do
    title { Faker::Lorem.words(7).join(' ') }
    description { Faker::Lorem.sentences(3).join(' ') }

    trait :with_reminders do
      after(:build) do |project|
        project.reminders << FactoryBot.create(:reminder, :project)
      end
    end

    trait :with_documents do
      after(:build) do |project|
        project.project_documents << FactoryBot.build(:project_document)
        project.project_documents << FactoryBot.build(:project_document)
      end
    end

    trait :with_named_documents do
      after(:build) do |project|
        project.project_documents << FactoryBot.build(:project_document, :title => "Final Report")
        project.project_documents << FactoryBot.build(:project_document, :title => "Project Document")
      end
    end

    trait :with_performance_indicators do
      after(:build) do |project|
        performance_indicator_ids = PerformanceIndicator.joins(:activity => {:outcome => {:planned_result => {:strategic_priority => :strategic_plan}}}).merge(StrategicPlan.current).pluck(:id)
        project.performance_indicator_ids = performance_indicator_ids.last(3)
      end
    end

    trait :with_mandate do 
      mandate_id { Mandate.pluck(:id).sample }
    end

    trait :with_subareas do 
      after(:build) do |project|
        project.project_subarea_ids = ProjectSubarea.first(4).map(&:id)
      end
    end

  end
end
