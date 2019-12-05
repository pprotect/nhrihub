class RoleAdministrationLogger

  def self.after_save(role)
    RoleAssignment.create(assigner_id: role.administrator&.id, action: 'create', assignee_id: nil, role_name: role.name)
  rescue PG::UndefinedTable
  end

  def self.after_destroy(role)
    RoleAssignment.create(assigner_id: role.administrator&.id, action: 'delete', assignee_id: nil, role_name: role.name)
  end
end
