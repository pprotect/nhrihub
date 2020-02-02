FactoryBot.define do
  factory :status_change do
    user_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }

    ComplaintStatus::Names.each { |name|
      sym = name.downcase.gsub(/ /,'_').to_sym
      trait sym do
        close_memo { sym == :closed ? 'No jurisdiction' : nil }
        after(:create) do |status_change|
          status_change.complaint_status = ComplaintStatus.find_or_create_by(:name => name)
        end
      end
    }

  end
end
