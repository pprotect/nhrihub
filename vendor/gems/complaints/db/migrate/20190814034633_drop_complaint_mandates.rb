class DropComplaintMandates < ActiveRecord::Migration[6.0]
  def change
    drop_table :complaint_mandates do |t|
      t.integer :complaint_id
      t.integer :mandate_id
      t.timestamps
    end
  end
end
