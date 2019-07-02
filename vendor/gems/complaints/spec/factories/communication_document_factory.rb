FactoryBot.define do
  factory :communication_document do
    file                { LoremIpsumDocument.new.docfile }
    filesize            { 10000 + (30000*rand).to_i }
    filename            { "#{Faker::Lorem.words(2).join("_")}.pdf" }
    original_type       { "application/pdf" }
    title               { "#{Faker::Lorem.words(8).join(" ")}" }
  end
end
