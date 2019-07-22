class CreateAccessEventsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :access_events do |t|
      t.timestamps
      t.integer :user_id
      t.string :exception_type
      t.string :login
    end
  end
end
