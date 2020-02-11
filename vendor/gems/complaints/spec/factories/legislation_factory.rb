FactoryBot.define do
  factory :legislation do
    short_name { LEGISLATIONS.map{|l| l[:short_name]}.reject(&:blank?).sample }
    full_name { LEGISLATIONS.select{|l| l[:short_name]==short_name }.first[:full_name] }
  end
end

