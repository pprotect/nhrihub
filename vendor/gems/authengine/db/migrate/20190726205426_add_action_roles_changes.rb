class AddActionRolesChanges < ActiveRecord::Migration[6.0]
  def change
    create_table :action_role_changes do |table|
      table.timestamps
      table.integer :user_id
      table.integer :action_id
      table.integer :role_id
      table.boolean :enable
    end
  end
end
