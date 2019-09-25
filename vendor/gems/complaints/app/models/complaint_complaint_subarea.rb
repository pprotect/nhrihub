class ComplaintComplaintSubarea < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :complaint_subarea, foreign_key: :subarea_id
end

