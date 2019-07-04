namespace :nhri_docs do
  desc "task to invoke daily from cron. Mails reminders that are due today"
  task :mail_reminders => :environment do
    Reminder.send_reminders_due_today
  end
end

namespace :reminder do
  desc "create a reminder that is due today, that should be emailed with the nhri_docs:mail_reminders rake task"
  task :due_today => :environment do
    FactoryBot.create(:reminder, :media_appearance, :due_today)
  end
end
