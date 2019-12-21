class AddFieldsToComplaints < ActiveRecord::Migration[6.0]
  def change
    rename_column :complaints, :chiefly_title, :title # can it be an enum?
    add_column :complaints, :id_type, :integer, limit: 1, default: 0 # id or passport
    add_column :complaints, :id_value, :integer, limit: 8 # specific format with check digits, 13 digits
    add_column :complaints, :critical_reference_number_type, :string
    add_column :complaints, :critical_reference_number_value, :string
    add_column :complaints, :complaint_type, :integer, limit: 1, default: 0
    add_column :complaints, :organization_name, :string
    add_column :complaints, :organization_registration_number, :string
    add_column :complaints, :physical_address, :string
    add_column :complaints, :postal_address, :string
    add_column :complaints, :city, :string
    add_column :complaints, :province, :string
    add_column :complaints, :postal_code, :string # 0001 to 9999
    add_column :complaints, :cell_phone, :string
    add_column :complaints, :home_phone, :string
    add_column :complaints, :fax, :string
    add_column :complaints, :preferred_means, :integer, limit: 2 # mail, cell, home, fax, email
  end
end
