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

def admin_assigns(assignees)
  assignees = [assignees] unless assignees.is_a?(Array)
  if assignees.empty?
    []
  else
    assignees.each_with_index.map{|assignee, i| Assign.new(created_at: (5*i).days.ago, assignee: assignee) }
  end
end

FactoryBot.define do
  factory :complaint do
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
    mandate_id { Mandate.pluck(:id).sample(1).first }
    transient do
      assigned_to {[]}
    end
    assigns { admin_assigns(assigned_to) }

    trait :corporate_services do
      mandate_id { Mandate.strategic_plan.first.id }
    end

    trait :human_rights do
      mandate_id { Mandate.human_rights.first.id }
    end

    trait :special_investigations_unit do
      mandate_id { Mandate.siu.first.id }
    end

    trait :good_governance do
      mandate_id { Mandate.good_governance.first.id }
    end

    trait :with_associations do
      after :build do |complaint|
        complaint.complaint_areas << ComplaintArea.all.sample(2)
        complaint.complaint_subareas << ComplaintSubarea.all.sample(2)
        complaint.status_changes << FactoryBot.create(:status_change, :open, :change_date => DateTime.now, :user_id => User.all.sample.id)
        complaint.agency_ids = Agency.pluck(:id).sample(2)
      end
    end

    trait :with_fixed_associations do
      after :build do |complaint|
        complaint.complaint_areas << ComplaintArea.all
        complaint.complaint_subareas << ComplaintSubarea.all
        complaint.status_changes << FactoryBot.create(:status_change, :open, :change_date => DateTime.now, :user_id => User.all.sample.id)
        complaint.mandate_id = Mandate.pluck(:id).sample(1)
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
          assignees = [FactoryBot.create(:assignee), FactoryBot.create(:assignee)]
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
        complaint.status_changes = [FactoryBot.create(:status_change, :open, change_date: 4.days.ago),
                                    FactoryBot.create(:status_change, :closed, change_date: 20.days.ago)]
      end
    end

    trait :closed do
      after(:build) do |complaint|
        complaint.status_changes = [FactoryBot.create(:status_change, :closed, change_date: 4.days.ago),
                                    FactoryBot.create(:status_change, :open, change_date: 20.days.ago)]
      end
    end

    trait :under_evaluation do
      after(:build) do |complaint|
        complaint.status_changes = [FactoryBot.create(:status_change, :under_evaluation, change_date: 4.days.ago)]
      end
    end
  end
end
