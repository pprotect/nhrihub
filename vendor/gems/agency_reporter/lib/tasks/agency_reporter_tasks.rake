require Rails.root.join('app','domain_models','report_utilities','report_template.rb')

namespace :agencies do
  desc "Creates template for agencies list from a raw MSWord document lib/source_docs/agencies_list.docx"
  task :generate_agencies_list_template => :environment do
    ReportTemplate.new(AgenciesReport, :list => true)
  end
end
