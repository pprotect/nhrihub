class AddUserIdToComplaintTransfers < ActiveRecord::Migration[6.0]
  def change
    add_column :complaint_transfers, :user_id, :integer
  end
end
