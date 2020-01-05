class ChangeComplaintFields < ActiveRecord::Migration[6.0]
  def change
    remove_column :complaints, :village #obsolete
    remove_column :complaints, :critical_reference_number_type
    remove_column :complaints, :critical_reference_number_value
    remove_column :complaints, :complaint_type
    remove_column :complaints, :case_reference_alt #obsolete, ephemeral
    add_column :complaints, :type, :string
    add_column :complaints, :alt_id_type, :integer, :limit => 2
    add_column :complaints, :alt_id_value, :string
    add_column :complaints, :alt_id_other_type, :string
  end
end
