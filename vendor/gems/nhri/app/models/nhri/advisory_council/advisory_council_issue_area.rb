class Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea < Area
  has_many :advisory_council_issue_issue_areas, foreign_key: :area_id
  has_many :advisory_council_issues, :through => :advisory_council_issue_issue_areas
  has_many :advisory_council_issue_subareas, foreign_key: :area_id

  def url
    Rails.application.routes.url_helpers.nhri_advisory_council_advisory_council_issue_area_path(:en,id) if persisted?
  end
end
