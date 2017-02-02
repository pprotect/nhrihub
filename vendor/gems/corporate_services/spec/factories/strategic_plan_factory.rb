FactoryGirl.define do
  factory :strategic_plan do
    start_date Date.today

    trait :populated do
      after(:create) do |sp|
        sp.strategic_priorities << FactoryGirl.create(:strategic_priority, :populated, :strategic_plan_id => sp.id)
        sp.strategic_priorities << FactoryGirl.create(:strategic_priority, :populated, :strategic_plan_id => sp.id)
      end
    end

    trait :well_populated do
      after(:create) do |sp|
        sp.strategic_priorities << FactoryGirl.create(:strategic_priority, :well_populated, :strategic_plan_id => sp.id)
        sp.strategic_priorities << FactoryGirl.create(:strategic_priority, :well_populated, :strategic_plan_id => sp.id)
      end
    end
  end
end
