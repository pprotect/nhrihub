class ProjectProjectSubarea < ActiveRecord::Base
  belongs_to :project
  belongs_to :project_subarea, foreign_key: :subarea_id
end
