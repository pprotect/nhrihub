FactoryBot.define do
  factory :outcome do
    description { Faker::Lorem.words(number: 6).join(" ") }

    trait :populated do
      after(:create) do |o|
        o.activities << FactoryBot.create(:activity, :populated, :outcome_id => o.id)
      end
    end

    trait :well_populated do
      after(:create) do |o|
        o.activities << FactoryBot.create(:activity, :well_populated, :outcome_id => o.id)
        o.activities << FactoryBot.create(:activity, :well_populated, :outcome_id => o.id)
      end
    end
  end
end
