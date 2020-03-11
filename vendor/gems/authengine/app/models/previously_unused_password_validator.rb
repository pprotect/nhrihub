class PreviouslyUnusedPasswordValidator < ActiveModel::EachValidator
  def validate_each(user, password, value)
    previous_crypted_password = user.attribute_in_database(:crypted_password)
    new_crypted_password = user.encrypt(value)
    reused_last_pw = new_crypted_password == previous_crypted_password
    reused_prior_pw = user.previous_passwords.reload.map(&:crypted_password).any?{|pp| pp == new_crypted_password}
    user.errors.add(:password, "cannot be reused.") if reused_last_pw || reused_prior_pw
  end
end
