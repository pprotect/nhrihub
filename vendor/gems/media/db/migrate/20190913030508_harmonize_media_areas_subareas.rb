class HarmonizeMediaAreasSubareas < ActiveRecord::Migration[6.0]
  def change
    drop_table :media_areas
    drop_table :media_subareas

    create_table :media_media_areas do |t|
      t.integer :media_appearance_id
      t.integer :area_id
      t.timestamps
    end

    create_table :media_media_subareas do |t|
      t.integer :media_appearance_id
      t.integer :subarea_id
      t.timestamps
    end
  end
end
