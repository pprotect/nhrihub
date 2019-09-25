FactoryBot.define do
  factory :mandate do
    name { ["Human Rights", "Good Governance", "Special Investigations Unit"].sample }
  end
end
