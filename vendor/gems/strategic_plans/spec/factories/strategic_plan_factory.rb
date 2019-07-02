FactoryBot.define do
  factory :strategic_plan do
    start_date { nil }
    title {Faker::Lorem.sentence(8,false,0)}

    trait :populated do
      after(:create) do |sp|
        sp.strategic_priorities << FactoryBot.create(:strategic_priority, :populated, :strategic_plan_id => sp.id)
        sp.strategic_priorities << FactoryBot.create(:strategic_priority, :populated, :strategic_plan_id => sp.id)
      end
    end

    trait :well_populated do
      after(:create) do |sp|
        sp.strategic_priorities << FactoryBot.create(:strategic_priority, :well_populated, :strategic_plan_id => sp.id)
        sp.strategic_priorities << FactoryBot.create(:strategic_priority, :well_populated, :strategic_plan_id => sp.id)
      end
    end
  end
end
