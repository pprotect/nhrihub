class ChangeComplaintDateReceivedToDateTime < ActiveRecord::Migration[6.0]
  def up
    change_column :complaints, :date_received, :datetime
  end

  def down
    change_column :complaints, :date_received, :date
  end
end
