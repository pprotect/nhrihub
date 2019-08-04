class UserRole < ActiveRecord::Base
  attr_accessor :assigner
  belongs_to :user
  belongs_to :role

  after_create UserRoleAssignmentLogger
  after_destroy UserRoleAssignmentLogger
end
