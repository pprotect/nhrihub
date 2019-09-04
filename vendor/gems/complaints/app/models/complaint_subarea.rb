class ComplaintSubarea < Subarea
  def url
    Rails.application.routes.url_helpers.complaint_area_subarea_path(:en,area_id,id) if persisted?
  end
end
