class AccessEvent < ActiveRecord::Base
  belongs_to :user

  def to_s
    I18n.t("#{exception_type}.access_log_message", interpolation_attributes)
  end

  def interpolation_attributes
    attributes.symbolize_keys.merge!(user: user.to_s, roles: user&.roles_list)
  end
end
