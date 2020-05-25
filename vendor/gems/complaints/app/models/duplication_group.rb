class DuplicationGroup < ActiveRecord::Base
  has_many :complaints

  def self.cleanup
    Complaint.joins(:duplication_group).
      where('duplication_groups.complaints_count = 1').
      update_all(duplication_group_id: nil)

    where('complaints_count <= 1').destroy_all
  end

end
