class Authengine::UserMailer < ApplicationMailer
  # subject for each email type is configured in config/locales/views/mailers/user_mailer/**.yml
  def signup_notification(user)
    @url = authengine_activate_url(:activation_code => user.activation_code, :locale => I18n.locale)
    send_mail(user)
  end

  def activate_notification(user)
    @url = login_url(:locale => I18n.locale)
    send_mail(user)
  end

  def forgotten_password_notification(user)
    @url = admin_new_password_url(I18n.locale, user.password_reset_code)
    send_mail(user)
  end

  def lost_token_notification(user)
    @url = admin_register_new_token_request_url(I18n.locale, user.replacement_token_registration_code)
    send_mail(user)
  end

protected
  def send_mail(user)
    @recipient = user
    mail
  end
end
