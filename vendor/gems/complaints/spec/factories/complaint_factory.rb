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
  Faker::Lorem.words(number: l).join('_').downcase + ".docx"
end

def admin_assigns(assignees)
  assignees = [assignees] unless assignees.is_a?(Array)
  if assignees.empty?
    []
  else
    assignees.each_with_index.map{|assignee, i| Assign.new(created_at: (5*i).days.ago, assignee: assignee) }
  end
end

def first_names
  number = [1,2,3].sample
  names = []
  number.times do
    names << Faker::Name.first_name
  end
  names.join(' ')
end

def organization_registration
  [ Faker::SouthAfrica.pty_ltd_registration_number,
    Faker::SouthAfrica.close_corporation_registration_number,
    Faker::SouthAfrica.listed_company_registration_number,
    Faker::SouthAfrica.trust_registration_number].sample
end

def id_attribute
  type = [0,1].sample
  value = case type
          when 0
            Faker::SouthAfrica.id_number
          when 1
            Faker::Alphanumeric.alphanumeric(number: 9)
          end
  {type: type, value: value}
end

def sa_city
  Faker::Config.locale = "en-ZA"
  city = Faker::Address.city
  Faker::Config.locale = "en"
  city
end

def sa_province
  Faker::Config.locale = "en-ZA"
  province = Faker::Address.provinces
  Faker::Config.locale = "en"
  province
end

def sa_postal_code
  Faker::Config.locale = "en-ZA"
  post_code = Faker::Address.zip_code
  Faker::Config.locale = "en"
  post_code
end

FactoryBot.define do
  factory :complaint do
    firstName { first_names }
    lastName { Faker::Name.last_name }
    phone { Faker::PhoneNumber.phone_number }
    created_at { DateTime.now.advance(:days => (rand(365) - 730))}
    details { Faker::Lorem.paragraphs(number: 2).join(" ") }
    occupation { Faker::Company.profession }
    employer { Faker::Company.name }
    email { Faker::Internet.email }
    gender { ["m","f","o"].sample }
    dob { y=20+rand(40); m=rand(12); d=rand(31); Date.today.advance(:years => -y, :months => -m, :days => -d).to_s }
    complaint_area_id { ComplaintArea.pluck(:id).sample(1).first }

    title { Faker::Name.prefix }
    id_type { id_attribute[:type] }
    id_value { id_attribute[:value] }
    alt_id_type { Complaint.alt_id_types.keys.sample }
    alt_id_value { rand(10000000)+1000000 }
    organization_name { Faker::Company.name }
    organization_registration_number { organization_registration }
    physical_address { Faker::Address.street_address }
    postal_address { "PO Box #{rand(5000)}" }
    city { sa_city }
    province { sa_province }
    postal_code { sa_postal_code }
    cell_phone { Faker::SouthAfrica.cell_phone }
    home_phone { Faker::SouthAfrica.phone_number }
    fax { Faker::SouthAfrica.phone_number }
    preferred_means { [0,1,2,3].sample }

    transient do
      assigned_to {[]}
    end
    assigns { admin_assigns(assigned_to) }

    trait :corporate_services do
      complaint_area_id { ComplaintArea.find_or_create_by(:name => "Corporate Services").id }

      after :build do |complaint|
        complaint.complaint_subareas << ComplaintSubarea.corporate_services.sample(2)
      end
    end

    trait :human_rights do
      complaint_area_id { ComplaintArea.find_or_create_by(:name => "Human Rights").id }

      after :build do |complaint|
        complaint.complaint_subareas << ComplaintSubarea.human_rights.sample(2)
      end
    end

    trait :special_investigations_unit do
      complaint_area_id { ComplaintArea.find_or_create_by(:name => "Special Investigations Unit").id }

      after :build do |complaint|
        complaint.complaint_subareas << ComplaintSubarea.special_investigations_unit.sample(2)
      end
    end

    trait :good_governance do
      complaint_area_id { ComplaintArea.find_or_create_by(:name => "Good Governance").id }

      after :build do |complaint|
        complaint.complaint_subareas << ComplaintSubarea.good_governance.sample(2)
      end
    end

    trait :with_associations do
      after :build do |complaint|
        complaint.complaint_area = ComplaintArea.all.sample
        complaint.complaint_subareas << ComplaintSubarea.all.sample(2)
        complaint.status_changes << FactoryBot.create(:status_change, :open, :change_date => DateTime.now, :user_id => User.all.sample.id)
        complaint.agency_ids = Agency.pluck(:id).sample(2)
      end
    end

    trait :with_fixed_associations do
      after :build do |complaint|
        complaint.complaint_area = ComplaintArea.all.sample
        complaint.complaint_subareas << ComplaintSubarea.all
        complaint.status_changes << FactoryBot.create(:status_change, :open, :change_date => DateTime.now, :user_id => User.all.sample.id)
        complaint.complaint_area_id = ComplaintArea.pluck(:id).sample(1)
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

    factory :individual_complaint do
      type { 'IndividualComplaint' }
    end
  end
end
