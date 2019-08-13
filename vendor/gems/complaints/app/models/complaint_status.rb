class ComplaintStatus < ActiveRecord::Base
  has_many :status_changes
  Names = ["Open", "Closed", "Under Evaluation", "Suspended"]

  scope :with_status, ->(names){ where(name: names) }
end
