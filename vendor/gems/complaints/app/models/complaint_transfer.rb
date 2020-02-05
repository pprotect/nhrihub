class ComplaintTransfer < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :transferee, class_name: :office, foreign_key: :office_id
end
