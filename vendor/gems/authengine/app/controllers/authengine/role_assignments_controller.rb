class Authengine::RoleAssignmentsController < ApplicationController
  def index
    @role_assignments = RoleAssignment.order("created_at desc").all
  end
end
