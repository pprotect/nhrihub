FactoryGirl.define do
  factory :reminder do
    text { Faker::Lorem.sentences(2).join(' ') }
    reminder_type {["one-time", "weekly", "monthly", "quarterly", "semi-annual", "annual"].sample}
    start_date { Date.today.advance(:days => rand(365)) }

    after(:create) do |reminder|
      reminder.user = User.first
    end

    trait :due_today do
      reminder_type "one-time"
      start_date { DateTime.now }
      after(:create) do |reminder|
        reminder.user = User.first
        reminder.save
      end
    end

    trait :media_appearance do
      remindable_type "MediaAppearance"
    end

    trait :outreach_event do
      remindable_type "OutreachEvent"
    end

    trait :activity do
      remindable_type "Activity"
    end

    trait :advisory_council_issue do
      remindable_type "Nhri::AdvisoryCouncil::AdvisoryCouncilIssue"
    end

    trait :indicator do
      remindable_type "Nhri::Heading:Indicator"
    end

    trait :project do
      remindable_type "Project"
    end

    trait :complaint do
      remindable_type "Complaint"
    end
  end
end
