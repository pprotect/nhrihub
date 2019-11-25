FactoryBot.define do
  factory :advisory_council_minutes, :class => Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes do
    file                { LoremIpsumDocument.new.upload_file }
    filesize            { 10000 + (30000*rand).to_i }
    original_filename   { "#{Faker::Lorem.words(number: 2).join("_")}.docx" }
    lastModifiedDate    { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    date                { Faker::Time.between(from: 1.year.ago, to: Time.now) }
    original_type       { "docx" }
    user_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }
  end
end
