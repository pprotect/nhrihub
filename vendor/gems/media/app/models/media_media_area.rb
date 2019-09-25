class MediaMediaArea < ActiveRecord::Base
  belongs_to :media_appearance
  belongs_to :media_area, foreign_key: :area_id

  #def as_json(options={})
    #super({:except => [:updated_at, :created_at, :media_appearance_id, :id],
           #:methods => [:subarea_ids]})
  #end

  #def subarea_ids
    #media_appearance.subareas.where(:area_id => area_id).pluck('id')
  #end

end
