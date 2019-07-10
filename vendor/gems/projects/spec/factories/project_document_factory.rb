FactoryBot.define do
  factory :project_document do
    file              { LoremIpsumDocument.new.upload_file }
    title             { Faker::Lorem.words(7).join(' ') }
    #file_id           { SecureRandom.hex(30) }
    original_filename { Faker::Lorem.words(3).join('_')+".pdf" }
    original_type     { "application/pdf" }
    after(:create) do |doc|
      `touch tmp/uploads/store/#{doc.file_id}`
    end
  end
end
