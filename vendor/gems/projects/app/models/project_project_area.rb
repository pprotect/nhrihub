class ProjectProjectArea < ActiveRecord::Base
  belongs_to :project
  belongs_to :project_area, foreign_key: :area_id
end
