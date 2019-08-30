class ComplaintStatus < ActiveRecord::Base
  has_many :status_changes
  Names = ["Open", "Closed", "Under Evaluation", "Suspended"]

  scope :default, ->{ select(:id).where(name: ["Open", "Under Evaluation"])}
  scope :with_status, ->(ids){ where(id: ids) }
end
