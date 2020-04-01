class CreateOfficesOfficeGroups < ActiveRecord::Migration[6.0]
  def change
    create_table "office_groups", force: :cascade do |t|
      t.string "name"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
    end

    create_table "offices", force: :cascade do |t|
      t.integer "office_group_id"
      t.string "name"
      t.string "short_name"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      #t.integer "province_id"
    end
  end
end
