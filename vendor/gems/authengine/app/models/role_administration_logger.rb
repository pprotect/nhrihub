class RoleAdministrationLogger

  def self.after_save(role)
      RoleAssignment.create(assigner_id: role.administrator&.id, action: 'create', assignee_id: nil, role_name: role.name)
  rescue ActiveRecord::StatementInvalid
    # rescue from role_assignments postgres error relation does not exist
    # when bootstrapping a new app, the role_assignments table may not exist
  end

  def self.after_destroy(role)
    RoleAssignment.create(assigner_id: role.administrator&.id, action: 'delete', assignee_id: nil, role_name: role.name)
  end
end
