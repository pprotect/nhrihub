class AddSequenceIntegerToComplaintStatus < ActiveRecord::Migration[6.0]
  def change
    add_column :complaint_statuses, :sequence, :integer
  end
end
