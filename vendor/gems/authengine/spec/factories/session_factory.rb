FactoryBot.define do
  factory :session do
    login_date { Time.now }
    session_id { Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join ) }
    user_id { if User.count > 20 then User.pluck(:id).sample else FactoryBot.create(:user).id end }
  end
end
