class HarmonizeProjectMandateAreaSubarea < ActiveRecord::Migration[6.0]
  def change
    drop_table :project_project_types do |t|
      t.integer "project_id"
      t.integer "project_type_id"
      t.timestamps
    end

    drop_table :project_types do |t|
      t.string "name"
      t.integer "mandate_id"
      t.timestamps
    end

    drop_table :project_mandates do |t|
      t.integer "project_id"
      t.integer "mandate_id"
      t.timestamps
    end

    add_column :projects, :mandate_id, :integer

    create_table :project_project_areas do |t|
      t.integer "project_id"
      t.integer "area_id"
      t.timestamps
    end

    create_table :project_project_subareas do |t|
      t.integer "project_id"
      t.integer "subarea_id"
      t.timestamps
    end
  end
end
