class ComplaintStatus < ActiveRecord::Base
  has_many :status_changes
  # for reference and factories only... should always use the database as a source
  Names = ["Registered", "Assessment", "Investigation", "Closed"]

  scope :default, ->{ select(:id).where("name != 'Closed'") }
  scope :with_status, ->(ids){ where(id: ids) }
end
