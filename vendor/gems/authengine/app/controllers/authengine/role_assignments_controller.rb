class Authengine::RoleAssignmentsController < ApplicationController
  def index
    @role_assignments = RoleAssignment.all
  end
end
