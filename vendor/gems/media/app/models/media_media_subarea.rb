class MediaMediaSubarea < ActiveRecord::Base
  belongs_to :media_appearance
  belongs_to :media_subarea, foreign_key: :subarea_id
end
