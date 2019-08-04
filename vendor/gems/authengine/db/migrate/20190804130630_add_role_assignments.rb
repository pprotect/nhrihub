class AddRoleAssignments < ActiveRecord::Migration[6.0]
  def change
    create_table :role_assignments do |t|
      t.references :assigner
      t.references :assignee
      t.string :role_name
      t.string :action
      t.timestamps
    end
  end
end
