class CreateComplaintTransfers < ActiveRecord::Migration[6.0]
  def change
    create_table :complaint_transfers do |t|
      t.integer :complaint_id
      t.integer :office_id
      t.timestamps
    end
  end
end
