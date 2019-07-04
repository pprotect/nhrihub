class CreateMediaSubareasTable < ActiveRecord::Migration[5.2]
  def change
    unless ActiveRecord::Base.connection.table_exists? 'media_subareas'
      create_table :media_subareas do |t|
        t.integer :media_appearance_id
        t.integer :subarea_id
        t.timestamps
      end
    end
  end
end
