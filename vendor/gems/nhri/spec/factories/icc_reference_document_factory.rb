FactoryBot.define do
  factory :icc_reference_document do
    title               {Faker::Lorem.words(number: 4).join(' ')}
    file                { LoremIpsumDocument.new.upload_file }
    source_url          { Faker::Internet.url }
    filesize            { rand(1000000) + 10000 }
    original_filename   { Faker::Lorem.words(number: 4).join('_')+'.docx' }
    original_type       { "docx" }
    user_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }

    trait :with_reminder do
      after(:build) do |ref_doc|
        reminder = FactoryBot.create(:reminder,
                                      :reminder_type => 'weekly',
                                      :remindable_type => "IccReferenceDocument",
                                      :text => "don't forget the fruit gums mum",
                                      :user => User.first)
        ref_doc.reminders << reminder
      end
    end
  end
end
