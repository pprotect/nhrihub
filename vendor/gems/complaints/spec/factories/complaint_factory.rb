def rand_title
  l = rand(4)+4
  arr = []
  l.times do
    word = Faker::Lorem.word
    word = word.upcase == word ? word : word.capitalize
    arr << word
  end
  arr.join(' ')
end

def rand_filename
  l = rand(3)+3
  Faker::Lorem.words(l).join('_').downcase + ".docx"
end

FactoryBot.define do
  factory :complaint do
    case_reference  { "some string" }
    firstName { Faker::Name.first_name }
    lastName { Faker::Name.last_name }
    village { Faker::Address.city }
    phone { Faker::PhoneNumber.phone_number }
    created_at { DateTime.now.advance(:days => (rand(365) - 730))}
    details { Faker::Lorem.paragraphs(2).join(" ") }
    chiefly_title { Faker::Name.last_name }
    occupation { Faker::Company.profession }
    employer { Faker::Company.name }
    email { Faker::Internet.email }
    gender { ["m","f","o"].sample }
    dob { y=20+rand(40); m=rand(12); d=rand(31); Date.today.advance(:years => -y, :months => -m, :days => -d).to_s }

    trait :with_associations do
      after :build do |complaint|
        complaint.good_governance_complaint_bases << GoodGovernance::ComplaintBasis.all.sample(2)
        complaint.human_rights_complaint_bases << Nhri::ComplaintBasis.all.sample(2)
        complaint.special_investigations_unit_complaint_bases << Siu::ComplaintBasis.all.sample(2)
        complaint.status_changes << FactoryBot.create(:status_change, :open, :change_date => DateTime.now, :user_id => User.all.sample.id)
        complaint.mandate_id = Mandate.pluck(:id).sample(1)
        complaint.mandate_ids = Mandate.pluck(:id).sample(2)
        complaint.agency_ids = Agency.pluck(:id).sample(2)
      end
    end

    trait :with_fixed_associations do
      after :build do |complaint|
        complaint.good_governance_complaint_bases << GoodGovernance::ComplaintBasis.all
        complaint.human_rights_complaint_bases << Nhri::ComplaintBasis.all
        complaint.special_investigations_unit_complaint_bases << Siu::ComplaintBasis.all
        complaint.status_changes << FactoryBot.create(:status_change, :open, :change_date => DateTime.now, :user_id => User.all.sample.id)
        complaint.mandate_id = Mandate.pluck(:id).sample(1)
        complaint.mandate_ids = Mandate.pluck(:id).sample(2)
        complaint.agency_ids = Agency.pluck(:id).sample(2)
      end
    end

    trait :with_document do
      after :build do |complaint|
        complaint_document = FactoryBot.create(:complaint_document, :title => rand_title, :original_filename => rand_filename)
        complaint.complaint_documents << complaint_document
      end
    end

    trait :with_assignees do
      after(:create) do |complaint|
        # avoid creating too many users... creates login collisions
        if User.count > 20
          assignees = User.all.sample(2)
        else
          assignees = [FactoryBot.create(:assignee, :with_password), FactoryBot.create(:assignee, :with_password)]
        end
        assigns = assignees.map do |user|
          date = DateTime.now.advance(:days => -rand(365))
          Assign.create(:created_at => date, :assignee => user, :complaint_id => complaint.id )
        end
      end
    end

    trait :with_comm do
      after(:create) do |complaint|
        complaint.communications = [FactoryBot.create(:communication, :with_notes, :date => DateTime.now), FactoryBot.create(:communication, :with_notes, :date => DateTime.now.advance(:days => -7))]
      end
    end

    trait :with_notes do
      after(:create) do |complaint|
        rand(3).times do
          FactoryBot.create(:note, :complaint, :notable_id => complaint.id)
        end
      end
    end

    trait :with_two_notes do
      after(:create) do |complaint|
        2.times do
          FactoryBot.create(:note, :complaint, :notable_id => complaint.id, :created_at => DateTime.new(2017,5,5))
        end
      end
    end

    trait :with_reminders do
      after(:build) do |complaint|
        complaint.reminders << FactoryBot.create(:reminder, :complaint)
      end
    end

    trait :open do
      after(:build) do |complaint|
        complaint.status_changes = [FactoryBot.create(:status_change, :open)]
      end
    end

    trait :closed do
      after(:build) do |complaint|
        complaint.status_changes = [FactoryBot.create(:status_change, :closed)]
      end
    end
  end
end
