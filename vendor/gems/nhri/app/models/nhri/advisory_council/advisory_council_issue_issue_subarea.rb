class Nhri::AdvisoryCouncil::AdvisoryCouncilIssueIssueSubarea < ActiveRecord::Base
  belongs_to :advisory_council_issue
  belongs_to :advisory_council_issue_subarea, foreign_key: :subarea_id
end
