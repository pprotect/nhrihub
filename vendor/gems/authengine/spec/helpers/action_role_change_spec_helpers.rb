require 'rspec/core/shared_context'

module ActionRoleChangeSpecHelpers
  extend RSpec::Core::SharedContext
  def create_single_action_role
    admin_role = Role.where(name: 'admin').first
    controller = Controller.create(controller_name: 'admin/organizations', last_modified: DateTime.now)
    action = Action.create(controller_id: controller.id, action_name: 'index')
    ActionRole.create(role_id: admin_role.id, action_id: action.id)
  end
end
