FactoryBot.define do
  factory :human_rights_attribute, :class => Nhri::HumanRightsAttribute do
    description {Faker::Lorem.words(number: 5).join(' ')}
    heading_id {Nhri::Heading.pluck(:id).sample}
  end
end
