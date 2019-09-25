desc "populate the entire application"
task :populate => :environment do
  Note.destroy_all
  Reminder.destroy_all
  modules = ["users", "csp_reports", "projects", "complaints", "strategic_plan", "media", "nhri", "internal_documents"]
  modules.each do |mod|
    Rake::Task[mod+":populate"].invoke
  end
end

desc "remove user-added data and wipes database ready for 'go-live'"
task :depopulate => :environment do
  Note.destroy_all
  Reminder.destroy_all
  modules = ["users", "csp_reports", "projects", "complaints", "strategic_plan", "media", "nhri", "internal_documents", "access_events"]
  modules.each do |mod|
    Rake::Task[mod+":depopulate"].invoke
  end
end

namespace :csp_reports do
  desc "populates some csp reports"
  task :populate => "csp_reports:depopulate" do
    5.times do
      FactoryBot.create(:csp_report)
    end
  end

  desc "removes all csp reports"
  task :depopulate => :environment do
    CspReport.destroy_all
  end
end

namespace :access_events do
  desc "populates access log table"
  task :populate => "access_events:depopulate" do
    50.times do
      FactoryBot.create(:access_event)
    end
  end

  desc "removes all access log entries"
  task :depopulate => :environment do
    AccessEvent.destroy_all
  end
end
