class MediaIssueArea < Area
  def url
    Rails.application.routes.url_helpers.media_appearance_area_path(:en,id) if persisted?
  end
end
