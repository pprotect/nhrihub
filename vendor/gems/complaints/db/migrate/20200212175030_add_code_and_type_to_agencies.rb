class AddCodeAndTypeToAgencies < ActiveRecord::Migration[6.0]
  def change
    add_column :agencies, :code, :string
    add_column :agencies, :type, :string
    add_column :agencies, :province_id, :integer
  end
end
