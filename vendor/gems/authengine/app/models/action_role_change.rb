class ActionRoleChange < ActiveRecord::Base
  belongs_to :user
  belongs_to :action
  belongs_to :role

  def current_state
    enable ? "enabled" : "disabled"
  end

  def role_name
    role.name
  end
end
