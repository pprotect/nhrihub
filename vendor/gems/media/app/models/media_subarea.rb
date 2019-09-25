class MediaSubarea < Subarea
  has_many :media_media_subareas, :foreign_key => :subarea_id
  belongs_to :media_area, :foreign_key => :area_id

  def url
    Rails.application.routes.url_helpers.media_appearance_area_subarea_path(:en,area_id,id) if persisted?
  end
end
