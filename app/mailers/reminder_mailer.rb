class ReminderMailer < ApplicationMailer
  # Subject set in en.reminder_mailer.reminder.subject
  def reminder(reminder)
    @recipient = reminder.user
    @text = reminder.text
    @link = reminder.link
    @remindable_name = reminder.remindable_name
    mail
  end
end
