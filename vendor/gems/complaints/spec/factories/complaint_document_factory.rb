FactoryBot.define do
  factory :complaint_document do
    file                { LoremIpsumDocument.new.upload_file }
    title               { Faker::Lorem.words(4).join(" ") }
    filesize            { 10000 + (30000*rand).to_i }
    original_filename   { "#{Faker::Lorem.words(2).join("_")}.pdf" }
    lastModifiedDate    { Faker::Date.between(1.year.ago, Date.today) }
    original_type       { "application/pdf" }
  end
end
