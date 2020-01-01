class ChangeComplaintAreaAssociation < ActiveRecord::Migration[6.0]
  def change
    drop_table :complaint_complaint_areas
    drop_table :complaint_complaint_bases # obsolete, not used
    rename_column :complaints, :mandate_id, :complaint_area_id
  end
end
