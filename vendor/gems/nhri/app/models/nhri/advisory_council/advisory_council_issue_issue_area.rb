class Nhri::AdvisoryCouncil::AdvisoryCouncilIssueIssueArea < ActiveRecord::Base
  belongs_to :advisory_council_issue
  belongs_to :advisory_council_issue_area, foreign_key: :area_id
end
