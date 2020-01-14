class AddOwnMotionComplaintFields < ActiveRecord::Migration[6.0]
  def change
    add_column :complaints, :initiating_branch_id, :integer
  end
end
