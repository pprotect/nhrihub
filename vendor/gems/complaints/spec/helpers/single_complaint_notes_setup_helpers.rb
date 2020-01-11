require 'rspec/core/shared_context'
require_relative '../helpers/complaints_spec_setup_helpers'

module SingleComplaintNotesSetupHelpers
  extend RSpec::Core::SharedContext
  include ComplaintsSpecSetupHelpers

  before do
    create_complaint_areas
    create_subareas
    create_complaint_statuses
    create_agencies
    complaint = FactoryBot.create( :individual_complaint,
                       :open,
                       :with_associations,
                       :agencies => [Agency.first],
                       :assigned_to => [User.where(:login => 'admin').first, User.where(:login => 'admin').first],
                       :reminders=>[FactoryBot.create(:reminder, :complaint)],
                       :notes =>   [FactoryBot.create(:note, :complaint, :created_at => 3.days.ago.to_datetime),FactoryBot.create(:note, :advisory_council_issue, :created_at => 4.days.ago.to_datetime)])
    visit complaint_path(:en, complaint.id)
    open_notes_modal
  end
end

