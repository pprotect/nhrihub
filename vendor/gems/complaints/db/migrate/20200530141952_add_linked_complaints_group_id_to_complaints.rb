class AddLinkedComplaintsGroupIdToComplaints < ActiveRecord::Migration[6.0]
  def change
    create_table :linked_complaints_groups do |t|
      t.timestamps
      t.integer :complaints_count, default: 0
    end
    add_column :complaints, :linked_complaints_group_id, :integer
  end
end
