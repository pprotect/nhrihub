class MediaArea < Area
  has_many :media_media_areas, :foreign_key => :area_id
  has_many :media_subareas, :foreign_key => :area_id

  def url
    Rails.application.routes.url_helpers.media_appearance_area_path(:en,id) if persisted?
  end
end
