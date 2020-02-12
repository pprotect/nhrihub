class CreateDistrictMunicipalities < ActiveRecord::Migration[6.0]
  def change
    create_table :district_municipalities do |t|
      t.string :name
      t.string :code
      t.integer :province_id
      t.timestamps
    end
  end
end
