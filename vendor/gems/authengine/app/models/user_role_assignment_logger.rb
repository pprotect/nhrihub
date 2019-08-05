class UserRoleAssignmentLogger
  def self.after_create(user_role)
    RoleAssignment.create(assigner_id: user_role.assigner&.id, action: 'assign', assignee_id: user_role.user.id, role_name: user_role.role.name)
  end

  def self.after_destroy(user_role)
    RoleAssignment.create(assigner_id: user_role.assigner&.id, action: 'deassign', assignee_id: user_role.user.id, role_name: user_role.role.name)
  end
end
