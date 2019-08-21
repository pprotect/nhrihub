class DropComplaintMandates < ActiveRecord::Migration[6.0]
  def change
    drop_table :complaint_mandates
  end
end
