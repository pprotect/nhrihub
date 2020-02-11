class ComplaintLegislation < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :legislation
end
