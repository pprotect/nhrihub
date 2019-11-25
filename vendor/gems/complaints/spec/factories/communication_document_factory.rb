FactoryBot.define do
  factory :communication_document do
    file                { LoremIpsumDocument.new.upload_file }
    filesize            { 10000 + (30000*rand).to_i }
    original_filename   { "#{Faker::Lorem.words(number: 2).join("_")}.pdf" }
    original_type       { "application/pdf" }
    title               { "#{Faker::Lorem.words(number: 8).join(" ")}" }
  end
end
