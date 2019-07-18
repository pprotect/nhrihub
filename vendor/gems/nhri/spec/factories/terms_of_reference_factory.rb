FactoryBot.define do
  factory :terms_of_reference_version, :class => Nhri::AdvisoryCouncil::TermsOfReferenceVersion do
    file                { LoremIpsumDocument.new.upload_file }
    filesize            { 10000 + (30000*rand).to_i }
    original_filename   { "#{Faker::Lorem.words(2).join("_")}.docx" }
    revision_major      { rand(10) }
    revision_minor      { rand(9) }
    lastModifiedDate    { Faker::Date.between(1.year.ago, Date.today) }
    original_type       { "docx" }
    user_id             { User.pluck(:id).sample }
  end
end
