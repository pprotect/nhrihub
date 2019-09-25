class ProjectSubarea < Subarea
  belongs_to :project_area, foreign_key: :area_id

  DefaultNames = {
    "Human Rights" => ["Schools", "Report or Inquiry", "Awareness Raising", "Legislative Review",
                        "Amicus Curiae", "Convention Implementation", "UN Reporting", "Detention Facilities Inspection",
                        "State of Human Rights Report", "Other"],
    "Good Governance" => ["Own motion investigation", "Consultation", "Awareness raising", "Other"],
    "Special Investigations Unit" => ["PSU Review", "Report", "Inquiry", "Other"],
    "Corporate Services" => []
  }

  scope :good_governance, ->{ joins(:project_area).merge(ProjectArea.good_governance) }
  scope :human_rights, ->{ joins(:project_area).merge(ProjectArea.human_rights) }
  scope :special_investigations_unit, ->{ joins(:project_area).merge(ProjectArea.special_investigations_unit) }

  def url
    Rails.application.routes.url_helpers.project_area_subarea_path(:en,area_id,id) if persisted?
  end
end
