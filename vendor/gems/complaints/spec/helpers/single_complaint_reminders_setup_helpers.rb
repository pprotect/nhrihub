require 'rspec/core/shared_context'
require_relative '../helpers/complaints_spec_setup_helpers'

module SingleComplaintRemindersSetupHelpers
  extend RSpec::Core::SharedContext
  include ComplaintsSpecSetupHelpers

  before do
    populate_database
    visit complaint_path(:en, @complaint.id)
    expect(reminders_icon['data-count']).to eq "1"
    open_reminders_panel
  end

  def populate_database
    create_complaint_areas
    create_subareas
    create_agencies
    create_complaint_statuses
    @complaint = FactoryBot.create( :individual_complaint,
                       :with_associations,
                       :registered,
                       :assigned_to => [User.where(:login => 'admin').first, User.where(:login => 'admin').first],
                       :agencies => [Agency.first],
                       :reminders=>[FactoryBot.create(:reminder,
                                                      :complaint,
                                                      :reminder_type => 'weekly',
                                                      :start_date => Date.new(2015,8,19),
                                                      :text => "don't forget the fruit gums mum",
                                                      :user => User.first)])
  end
end
