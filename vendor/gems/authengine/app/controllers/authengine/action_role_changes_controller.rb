class Authengine::ActionRoleChangesController < ApplicationController
  def index
    @action_role_changes = ActionRoleChange.all
  end
end
