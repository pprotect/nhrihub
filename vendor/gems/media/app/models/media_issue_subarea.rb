class MediaIssueSubarea < Subarea
  def url
    Rails.application.routes.url_helpers.media_appearance_area_subarea_path(:en,area_id,id) if persisted?
  end
end
