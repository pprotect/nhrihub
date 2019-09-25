class Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea < Subarea
  has_one :advisory_council_issue_area, foreign_key: :area_id
  has_many :advisory_council_issue_issue_subareas, foreign_key: :subarea_id
  has_many :advisory_council_issues, :through => :advisory_council_issue_issue_subareas

  def url
    Rails.application.routes.url_helpers.nhri_advisory_council_advisory_council_issue_area_subarea_path(:en,area_id,id) if persisted?
  end
end
