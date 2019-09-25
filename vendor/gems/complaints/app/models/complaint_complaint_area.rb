class ComplaintComplaintArea < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :complaint_area, foreign_key: :area_id
end
