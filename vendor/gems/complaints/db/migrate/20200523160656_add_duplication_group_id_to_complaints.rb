class AddDuplicationGroupIdToComplaints < ActiveRecord::Migration[6.0]
  def change
    create_table :duplication_groups do |t|
      t.timestamps
      t.integer :complaints_count, default: 0
    end
    add_column :complaints, :duplication_group_id, :integer
  end
end
