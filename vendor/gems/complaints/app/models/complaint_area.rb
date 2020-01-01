class ComplaintArea < Area
  DefaultNames = ["Special Investigations Unit", "Human Rights", "Good Governance"]

  has_many :complaint_complaint_areas, foreign_key: :area_id
  has_many :complaint_subareas, foreign_key: :area_id

  scope :good_governance, ->{ where(name: "Good Governance") }
  scope :human_rights   , ->{ where(name: "Human Rights") }
  scope :special_investigations_unit, ->{ where(name: "Special Investigations Unit") }
  scope :corporate_services, ->{ where(name: "Corporate Services") }

  def url
    Rails.application.routes.url_helpers.complaint_area_path(:en,id) if persisted?
  end

  def key
    name.downcase.gsub(/\s/,'_')
  end
end
