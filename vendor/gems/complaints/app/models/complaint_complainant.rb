class ComplaintComplainant < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :complainant
end
