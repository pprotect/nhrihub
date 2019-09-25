class HarmonizeComplaintsAreasSubareasTables < ActiveRecord::Migration[6.0]
  def change

    create_table "complaint_complaint_areas" do |t|
      t.integer :complaint_id
      t.integer :area_id
      t.timestamps
    end

    create_table "complaint_complaint_subareas" do |t|
      t.integer :complaint_id
      t.integer :subarea_id
      t.timestamps
    end
  end
end
