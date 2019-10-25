human_rights_subareas = ["Violation", "Education activities", "Office reports", "Universal periodic review", "CEDAW", "CRC", "CRPD"]
good_governance_subareas = ["Violation", "Office report", "Office consultations"]

FactoryBot.define do
  factory :project_subarea do
    type { 'ProjectSubarea' }

    trait :human_rights do
      name { human_rights_subareas.sample }
      area_id { ProjectArea.find_or_create_by(:name => 'Human Rights').id }
    end

    trait :good_governance do
      name { good_governance_subareas.sample }
      area_id { ProjectArea.find_or_create_by(:name => 'Good Governance').id }
    end

    trait :siu do
      name { good_governance_subareas.sample }
      area_id { ProjectArea.find_or_create_by(:name => 'Special Investigations Unit').id }
    end

    trait :other do
      name { "a subarea" }
      area_id { ProjectArea.where(:name => 'Other').first.id }
    end
  end

  factory :complaint_subarea do
    type { 'ComplaintSubarea' }

    trait :human_rights do
      name { human_rights_subareas.sample }
      area_id { ComplaintArea.find_or_create_by(:name => 'Human Rights').id }
    end

    trait :good_governance do
      name { good_governance_subareas.sample }
      area_id { ComplaintArea.find_or_create_by(:name => 'Good Governance').id }
    end

    trait :siu do
      name { good_governance_subareas.sample }
      area_id { ComplaintArea.find_or_create_by(:name => 'Special Investigations Unit').id }
    end

    trait :other do
      name { "a subarea" }
      area_id { ComplaintArea.where(:name => 'Other').first.id }
    end
  end

  factory :issue_subarea, class: Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea do
    type { 'Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea' }

    trait :human_rights do
      name { human_rights_subareas.sample }
      area_id { Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => 'Human rights').first.id }
    end

    trait :good_governance do
      name { good_governance_subareas.sample }
      area_id { Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => 'Good governance').first.id }
    end

    trait :other do
      name { "a subarea" }
      area_id { Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => 'Other').first.id }
    end
  end

end
