FactoryBot.define do
  factory :note do
    text { Faker::Lorem.sentence(10) }
    author_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }
    editor_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }

    trait :media_appearance do
      notable_type { "MediaAppearance" }
    end

    trait :activity do
      notable_type { "Activity" }
    end

    trait :advisory_council_issue do
      notable_type { "Nhri::AdvisoryCouncil::AdvisoryCouncilIssue" }
    end

    trait :indicator do
      notable_type { "Nhri::Heading:Indicator" }
    end

    trait :project do
      notable_type { "Project" }
    end

    trait :complaint do
      notable_type { "Complaint" }
    end

    trait :communication do
      notable_type { "Communication" }
    end
  end
end
