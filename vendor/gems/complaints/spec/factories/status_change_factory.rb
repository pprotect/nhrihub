FactoryBot.define do
  factory :status_change do
    user_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }

    # Names = ["Registered", "Assessment", "Investigation", "Closed"]
    # CloseMemoOptions = ["No jurisdiction", "Alternative remedies", "Expire, no special circumstances"]
    trait :closed do
      after(:create) do |status_change|
        status_change.complaint_status = ComplaintStatus.find_or_create_by(:name => "Closed")
      end
    end

    trait :preset do
      status_memo { ComplaintStatus::CloseMemoOptions.sample }
      status_memo_type { 'close_preset' }
    end

    trait :referred do
      status_memo { 'another agency' }
      status_memo_type { 'close_referred_to' }
    end

    trait :other do
      status_memo { 'a different reason' }
      status_memo_type { 'close_other_reason' }
    end

    trait :registered do
      status_memo { nil }
      status_memo_type { 'non_existent' }
      after(:create) do |status_change|
        status_change.complaint_status = ComplaintStatus.find_or_create_by(:name => "Registered")
      end
    end

    trait :investigation do
      status_memo { nil }
      status_memo_type { 'non_existent' }
      after(:create) do |status_change|
        status_change.complaint_status = ComplaintStatus.find_or_create_by(:name => "Investigation")
      end
    end

    trait :assessment do
      status_memo { 'Information pending' }
      status_memo_type { 'assessment' }
      after(:create) do |status_change|
        status_change.complaint_status = ComplaintStatus.find_or_create_by(:name => "Assessment")
      end
    end
  end
end
