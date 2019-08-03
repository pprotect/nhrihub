class ComplaintStatus < ActiveRecord::Base
  has_many :status_changes
  scope :open, ->{ where(:name => 'Open') }
end
