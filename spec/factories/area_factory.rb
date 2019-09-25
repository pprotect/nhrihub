FactoryBot.define do
  factory :complaint_area, class: ComplaintArea do
    name { 'an area' }
    type { 'ComplaintArea' }
  end

  factory :media_area, class: MediaArea do
    name { 'an area' }
    type { 'MediaArea' }
  end

  factory :issue_area, class: Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea do
    name { 'an area' }
    type { 'Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea' }
  end
end
