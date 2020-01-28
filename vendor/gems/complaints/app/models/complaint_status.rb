class ComplaintStatus < ActiveRecord::Base
  has_many :status_changes
  # for reference and factories only... should always use the database as a source
  Names = ["Registered", "Assessment", "Investigation", "Closed"]
  CloseMemoOptions = ["No jurisdiction", "Alternative remedies", "Expire, no special circumstances"]

  scope :default, ->{ select(:id).where("name != 'Closed'") }
  scope :with_status, ->(ids){ where(id: ids) }
end
