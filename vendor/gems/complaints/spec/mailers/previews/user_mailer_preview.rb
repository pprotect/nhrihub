class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/signup_notification
  def signup_notification
    Authengine::UserMailer.signup_notification(User.first)
  end

  def activate_notification
    Authengine::UserMailer.activate_notification(User.first)
  end

  def forgotten_password_notification
    Authengine::UserMailer.forgotten_password_notification(User.first)
  end

  def lost_token_notification
    Authengine::UserMailer.lost_token_notification(User.first)
  end
end
