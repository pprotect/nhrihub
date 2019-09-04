class ComplaintArea < Area
  def url
    Rails.application.routes.url_helpers.complaint_area_path(:en,id) if persisted?
  end
end
