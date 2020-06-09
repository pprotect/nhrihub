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

def organization_registration
  [ Faker::SouthAfrica.pty_ltd_registration_number,
    Faker::SouthAfrica.close_corporation_registration_number,
    Faker::SouthAfrica.listed_company_registration_number,
    Faker::SouthAfrica.trust_registration_number].sample
end

def rand_filename
  l = rand(3)+3
  Faker::Lorem.words(number: l).join('_').downcase + ".docx"
end

def transfer_to(transferred_to) 
  return [] if transferred_to.nil?
  if transferred_to.is_a? Integer
    office_id = transferred_to
  else
    office_id = transferred_to.id
  end
  [ComplaintTransfer.new( office_id: office_id )]
end

def admin_assigns(assignees)
  assignees = [assignees] unless assignees.is_a?(Array)
  if assignees.empty?
    []
  else
    assignees.
      each_with_index.
      map{|assignee, i| Assign.new(created_at: (5*(i+1)).days.ago, assignee: assignee, assigner:assignee) }
  end
end

FactoryBot.define do
  factory :complaint do
    created_at { DateTime.now.advance(:days => (rand(365) - 730))}
    details { Faker::Lorem.paragraphs(number: 2).join(" ") }
    desired_outcome { Faker::Lorem.paragraphs(number: 2).join(" ") }
    complaint_area_id { ComplaintArea.pluck(:id).sample(1).first }
    organization_name { Faker::Company.name }
    organization_registration_number { organization_registration }
    after :build do |complaint|
      complaint.complainants << FactoryBot.create(:complainant)
    end

    transient do
      assigned_to {[]}
      transferred_to {}
    end
    assigns { admin_assigns(assigned_to) }
    complaint_transfers { transfer_to(transferred_to) }

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
        complaint.status_changes << FactoryBot.create(:status_change, :registered, :change_date => DateTime.now.advance(days: -(356+rand(365))), :user_id => User.all.sample.id)
        status = (ComplaintStatus::Names - ["Registered"]).map{|name| name.downcase.to_sym}.sample
        complaint.status_changes << FactoryBot.create(:status_change, status, :change_date => DateTime.now.advance(months: -1), :user_id => User.all.sample.id)
        complaint.agency_ids = Agency.pluck(:id).sample(2)
      end
    end

    trait :with_fixed_associations do
      after :build do |complaint|
        complaint.complaint_area = ComplaintArea.all.sample
        complaint.complaint_subareas << ComplaintSubarea.all
        status = ComplaintStatus::Names.map{|name| name.downcase.gsub(/ /,'_').to_sym}.sample
        complaint.status_changes << FactoryBot.create(:status_change, status, :change_date => DateTime.now, :user_id => User.all.sample.id)
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
        another_user = User.order('RANDOM()').first
        assigns = assignees.map do |user|
          date = DateTime.now.advance(:days => -rand(365))
          Assign.create(:created_at => date, :assigner => another_user, :assignee => user, :complaint_id => complaint.id )
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

    trait :closed do
      after(:build) do |complaint|
        complaint.status_changes = [FactoryBot.create(:status_change, :closed, :preset_jurisdiction, change_date: 4.days.ago),
                                    FactoryBot.create(:status_change, :registered, change_date: 20.days.ago)]
      end
    end

    ComplaintStatus::Names.each { |name|
      sym = name.downcase.gsub(/ /,'_').to_sym
      trait sym do
        after(:build) do |complaint|
          complaint.status_changes = [FactoryBot.create(:status_change, sym, change_date: 4.days.ago),
                                      FactoryBot.create(:status_change, :registered, change_date: 20.days.ago)]
        end
      end
    }

    factory :individual_complaint, class: "IndividualComplaint" do
      type { 'IndividualComplaint' }
    end

    factory :organization_complaint, class: "OrganizationComplaint" do
      type { 'OrganizationComplaint' }
      organization_name { Faker::Company.name }
      organization_registration_number {  10000000 + rand(10000000) }
    end

    factory :own_motion_complaint, class: "OwnMotionComplaint" do
      type { 'OwnMotionComplaint' }
      initiating_office_id { Office.not_branches.map(&:id).sample }
      initiating_branch_id { Office.branches.map(&:id).sample }
    end
  end
end
