require 'faker'
get_name = proc{
uu = User.pluck(:login)
nn = Faker::Name.last_name
until(!uu.include?(nn)) do (nn = Faker::Name.last_name) end
nn}

FactoryBot.define do
  factory :user, :aliases => [:assignee] do
    login {get_name.call}
    email {Faker::Internet.email}
    activated_at {Date.today - rand(365)}
    enabled { 1 }
    firstName {Faker::Name.first_name}
    lastName {Faker::Name.last_name}

    after(:create) do |user|
      user.update_attribute(:salt, '1641b615ad281759adf85cd5fbf17fcb7a3f7e87')
      user.update_attribute(:activation_code, Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join ))
      user.update_attribute(:activated_at, DateTime.new(2011,1,1))
      user.update_attribute(:crypted_password, '660030f1be7289571b0467b9195ff39471c60651')
      user
    end

    trait :admin do
      after(:build) do |u|
        if Role.exists?(:name => 'admin')
          u.roles. << Role.where(:name => 'admin').first
        else
          u.roles << FactoryBot.build(:admin_role)
        end
      end
    end

    trait :staff do
      after(:build) do |u|
        if Role.exists?(:name => 'staff')
          u.roles << Role.where(:name => 'staff').first
        else
          u.roles << FactoryBot.build(:staff_role)
        end
      end
    end
  end

end
