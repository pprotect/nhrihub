class CreatePreviousPasswords < ActiveRecord::Migration[6.0]
  def change
    create_table :previous_passwords do |t|
      t.integer :user_id
      t.string :crypted_password
      t.timestamps
    end
  end
end
