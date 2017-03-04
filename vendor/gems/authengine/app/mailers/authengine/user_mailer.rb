class Authengine::UserMailer < ActionMailer::Base
  # subject for each email type is configured in config/locales/views/mailers/user_mailer/**.yml
  def signup_notification(user)
    setup_email(user)
    @url = authengine_activate_url(:activation_code => user.activation_code, :locale => I18n.locale)
    mail( :to => @recipients,
          :subject => t('.subject', org_name: ORGANIZATION_NAME, app_name: APPLICATION_NAME),
          :date => @sent_on,
          :from => @from
        )
  end

  def activate_notification(user)
    setup_email(user)
    @url = login_url(:locale => I18n.locale)
    mail( :to => @recipients,
          :subject => t('.subject'),
          :date => @sent_on,
          :from => @from
        )
  end

  def forgotten_password_notification(user)
    setup_email(user)
    @url  = "http://#{SITE_URL}/#{I18n.locale}/admin/new_password/#{user.password_reset_code}"
    mail( :to => @recipients,
          :subject => t('.subject'),
          :date => @sent_on,
          :from => @from
        )
  end

  def reset_password_notification(user)
    setup_email(user)
    @subject = t('.subject')
  end

  def lost_token_notification(user)
    setup_email(user)
    @url  = "http://#{SITE_URL}/#{I18n.locale}/admin/register_replacement_token_request/#{user.replacement_token_registration_code}"
    mail( :to => @recipients,
          :subject => t('.subject'),
          :date => @sent_on,
          :from => @from
        )
  end

  def message_to_admin(subject,body)
    @admin = User.find_by_login('admin')
    @recipients  = @admin.email
    @from        = @admin.email
    @subject     = "#{APPLICATION_NAME || "database"} - "
    @sent_on     = Time.now
    @subject    += subject
    @body  = body
  end

protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "#{APPLICATION_NAME || "database"} Administrator<#{ADMIN_EMAIL}>"
    @sent_on     = Time.now
    @user        = user
  end
end
