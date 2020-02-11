class CreateLegislations < ActiveRecord::Migration[6.0]
  def change
    create_table :legislations do |t|
      t.string :short_name
      t.string :full_name
      t.timestamps
    end

    create_table :complaint_legislations do |t|
      t.integer :legislation_id
      t.integer :complaint_id
      t.timestamps
    end
  end
end
