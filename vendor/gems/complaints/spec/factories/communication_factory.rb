FactoryBot.define do
  factory :communication do
    mode { ['phone','email','letter','face to face'].sample }
    direction {['sent','received'].sample}
    date { DateTime.now }
    user_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }
    after(:build) do |communication|
      communication.communication_documents << FactoryBot.create(:communication_document)
      communication.communicants << FactoryBot.create(:communicant)
    end

    trait :with_notes do
      after(:create) do |communication|
        2.times do
          FactoryBot.create(:note, :communication, :notable_id => communication.id)
        end
      end
    end
  end
end
