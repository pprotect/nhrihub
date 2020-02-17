class ChangeLocalMunicipalityProvinceIdToDistrictId < ActiveRecord::Migration[6.0]
  def change
    add_column :agencies, :district_id, :integer
  end
end
