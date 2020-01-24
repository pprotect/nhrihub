FactoryBot.define do
  factory :complaint_status do
    name  { "oogly woo" }

    ComplaintStatus::Names.each { |name|
      sym = name.downcase.gsub(/ /,'_').to_sym
      trait sym do
        name { name }
      end
    }
  end
end
