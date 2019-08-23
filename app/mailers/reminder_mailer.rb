class ReminderMailer < ApplicationMailer
  default from: "#{APPLICATION_NAME || "database"} Administrator<#{NO_REPLY_EMAIL}>"

  # Subject set in en.reminder_mailer.reminder.subject
  def reminder(reminder)
    @recipient = reminder.user
    @text = reminder.text
    @link = reminder.link
    @remindable_name = reminder.remindable_name
    mail
  end
end
