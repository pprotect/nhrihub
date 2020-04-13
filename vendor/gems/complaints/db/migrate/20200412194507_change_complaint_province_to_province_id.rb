class ChangeComplaintProvinceToProvinceId < ActiveRecord::Migration[6.0]
  def change
    remove_column :complaints, :province
    add_column :complaints, :province_id, :integer, limit: 2, default: 0
  end
end
