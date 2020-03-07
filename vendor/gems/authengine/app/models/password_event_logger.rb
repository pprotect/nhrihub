class PasswordEventLogger
  def self.before_update(user)
    if user.will_save_change_to_attribute?(:crypted_password) 
      user.password_expiry_date = Date.today.advance(days: 30)
      AccessEvent.create(exception_type: 'user/expired_password_replacement', user: user) unless user.password_expiry_token.blank?
      AccessEvent.create(exception_type: 'user/admin_reset_password_replacement', user: user) unless user.password_reset_code.blank?
      user.password_expiry_token = nil
      user.password_reset_code = nil
    end
  end
end
