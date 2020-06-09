class RemoveUnusedColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :complainants, :phone
    remove_column :complaints, :case_reference
  end
end
