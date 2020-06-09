class RenameComplaintComplainants < ActiveRecord::Migration[6.0]
  def change
    rename_table :complaint_complainants, :complainants_complaints
  end
end
