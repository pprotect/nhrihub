class ComplaintSubarea < Subarea
  belongs_to :complaint_area, foreign_key: :area_id

  scope :good_governance, ->{ joins(:complaint_area).merge(ComplaintArea.good_governance) }
  scope :human_rights, ->{ joins(:complaint_area).merge(ComplaintArea.human_rights) }
  scope :special_investigations_unit, ->{ joins(:complaint_area).merge(ComplaintArea.special_investigations_unit) }

  def url
    Rails.application.routes.url_helpers.complaint_area_subarea_path(:en,area_id,id) if persisted?
  end
end
