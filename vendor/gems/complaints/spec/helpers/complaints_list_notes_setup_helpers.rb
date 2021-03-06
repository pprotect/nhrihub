require 'rspec/core/shared_context'
require_relative '../helpers/complaints_spec_setup_helpers'

module ComplaintsContextNotesSpecHelpers
  extend RSpec::Core::SharedContext
  include ComplaintsSpecSetupHelpers

  before do
    create_complaint_areas
    create_subareas
    create_complaint_statuses
    create_agencies
    FactoryBot.create( :individual_complaint,
                       :with_associations,
                       :assessment,
                       :agencies => [Agency.first],
                       :assigned_to => [User.where(:login => 'admin').first, User.where(:login => 'admin').first],
                       :reminders=>[FactoryBot.create(:reminder, :complaint)],
                       :notes =>   [FactoryBot.create(:note, :complaint, :created_at => 3.days.ago.to_datetime),FactoryBot.create(:note, :advisory_council_issue, :created_at => 4.days.ago.to_datetime)])
    resize_browser_window
    visit complaints_path(:en)
    open_notes_modal
  end
end

