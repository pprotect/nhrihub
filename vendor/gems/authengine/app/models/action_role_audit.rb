module ActionRoleAudit
  def self.after_create(action_role)
    ActionRoleChange.create(user: action_role.changed_by, enable: 1, action_description: action_role.action.description, role: action_role.role)
  end

  def self.after_destroy(action_role)
    ActionRoleChange.create(user: action_role.changed_by, enable: 0, action_description: action_role.action.description, role: action_role.role)
  end
end
