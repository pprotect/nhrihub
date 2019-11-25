FactoryBot.define do
  factory :access_event do
    user_id { User.pluck(:id).sample }
    exception_type {['login', 'logout', 'user/token_not_registered',
                     'user/login_blank', 'user/invalid_password',
                     'user/login_not_found', 'user/account_not_activated',
                     'user/account_disabled' ].sample }
    login { Faker::Lorem.words[number: 1] }
    request_ip { Faker::Internet.ip_v4_address }
    request_user_agent { Faker::Internet.user_agent }
    created_at { DateTime.now.advance(days: -rand(365), hours: -rand(24)) }
    updated_at { DateTime.now.advance(days: -rand(365), hours: -rand(24)) }
  end
end
