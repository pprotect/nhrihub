class AddInitiatingOfficeIdToComplaints < ActiveRecord::Migration[6.0]
  def change
    add_column :complaints, :initiating_office_id, :integer
  end
end
