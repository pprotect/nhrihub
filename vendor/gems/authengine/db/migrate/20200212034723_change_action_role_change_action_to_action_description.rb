class ChangeActionRoleChangeActionToActionDescription < ActiveRecord::Migration[6.0]
  def change
    remove_column :action_role_changes, :action
    add_column :action_role_changes, :action_description, :string
  end
end
