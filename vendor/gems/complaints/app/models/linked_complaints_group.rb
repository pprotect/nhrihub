class LinkedComplaintsGroup < ActiveRecord::Base
  has_many :complaints

  def self.cleanup
    Complaint.joins(:linked_complaints_group).
      where('linked_complaints_groups.complaints_count = 1').
      update_all(linked_complaints_group_id: nil)

    where('complaints_count <= 1').destroy_all
  end
end
