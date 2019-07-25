class AccessEvent < ActiveRecord::Base
  belongs_to :user

  default_scope { order( "created_at DESC") }

  def interpolation_attributes
    attributes.symbolize_keys.merge!(user: user.to_s, roles: user&.roles_list)
  end
end
