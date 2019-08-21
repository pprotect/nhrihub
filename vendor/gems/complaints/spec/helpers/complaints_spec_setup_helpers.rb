require 'rspec/core/shared_context'

module ComplaintsSpecSetupHelpers
  extend RSpec::Core::SharedContext

  def complete_required_fields
    within new_complaint do
      fill_in('lastName', :with => "Normal")
      fill_in('firstName', :with => "Norman")
      fill_in('dob', :with => "08/09/1950")
      fill_in('village', :with => "Normaltown")
      fill_in('complaint_details', :with => "a long story about lots of stuff")
      choose('special_investigations_unit')
      choose('complained_to_subject_agency_yes')
      check_basis(:good_governance, "Delayed action")
      select(User.admin.first.first_last_name, :from => "assignee")
    end
  end

  def populate_database
    create_mandates
    create_agencies
    create_staff
    create_complaint_statuses
    user = User.where(:login => 'admin').first
    staff_user = User.where(:login => 'staff').first
    FactoryBot.create(:complaint, :open,
                      :assigned_to => [user, staff_user],
                      :case_reference => "c12-34",
                      :date_received => DateTime.now.advance(:days => -100),
                      :village => Faker::Address.city,
                      :phone => Faker::PhoneNumber.phone_number,
                      :dob => "19/08/1950",
                      :human_rights_complaint_bases => hr_complaint_bases,
                      :good_governance_complaint_bases => gg_complaint_bases,
                      :special_investigations_unit_complaint_bases => siu_complaint_bases,
                      :desired_outcome => Faker::Lorem.sentence,
                      :details => Faker::Lorem.sentence,
                      :complaint_documents => complaint_docs,
                      :mandate_id => _mandate_id,
                      :agencies => _agencies,
                      :communications => _communications)
    FactoryBot.create(:complaint, :closed,
                      :case_reference => "c12-42",
                      :assigned_to => [user, staff_user],
                      :date_received => DateTime.now.advance(:days => -100),
                      :village => Faker::Address.city,
                      :phone => Faker::PhoneNumber.phone_number,
                      :dob => "19/08/1950",
                      :human_rights_complaint_bases => hr_complaint_bases,
                      :good_governance_complaint_bases => gg_complaint_bases,
                      :special_investigations_unit_complaint_bases => siu_complaint_bases,
                      :desired_outcome => Faker::Lorem.sentence,
                      :details => Faker::Lorem.sentence,
                      :complaint_documents => complaint_docs,
                      :mandate_id => _mandate_id,
                      :agencies => _agencies,
                      :communications => _communications)
    set_file_defaults
  end

  def create_complaints
    admin = User.where(:login => 'admin').first
    assignees = [admin, admin]
    FactoryBot.create(:complaint, :open, :assigned_to => assignees, :case_reference => "c12-22")
    FactoryBot.create(:complaint, :open, :assigned_to => assignees, :case_reference => "c12-33")
    @complaint = FactoryBot.create(:complaint, :open, :assigned_to => assignees, :case_reference => "c12-55")
  end

  private
  def set_file_defaults
    SiteConfig["complaint_document.filetypes"]=["pdf"]
    SiteConfig["complaint_document.filesize"]= 5
    SiteConfig["communication_document.filetypes"]=["pdf"]
    SiteConfig["communication_document.filesize"]= 5
  end

  def create_staff
    2.times do
      FactoryBot.create(:user, :staff, :firstName => Faker::Name.unique.first_name, :lastName => Faker::Name.unique.last_name)
    end
  end

  def create_mandates
    [:good_governance, :human_rights, :special_investigations_unit, :strategic_plan].each do |key|
      FactoryBot.create(:mandate, :key => key)
    end
  end

  def create_complaint_statuses
    ["Open", "Incomplete", "Closed"].each do |status_name|
      FactoryBot.create(:complaint_status, :name => status_name)
    end
  end

  def _communications
    [ FactoryBot.create(:communication) ]
  end

  def _mandate_id
    Mandate.find_by(:key => 'human_rights' ).id
  end

  def _agencies
    [ Agency.find_by(:name => 'SAA') ]
  end

  def complaint_docs
    Array.new(2) { FactoryBot.create(:complaint_document) }
  end

  def hr_complaint_bases
    names = ["CAT", "ICESCR"]
    @hr_complaint_bases ||= names.collect{|name| FactoryBot.create(:convention, :name => name)}
  end

  def gg_complaint_bases
    names = ["Delayed action", "Failure to act", "Contrary to Law", "Oppressive", "Private"]
    @gg_complaint_bases ||= names.collect{|name| FactoryBot.create(:good_governance_complaint_basis, :name => name) }
    names = ["Delayed action", "Failure to act"]
    GoodGovernance::ComplaintBasis.where(:name => names)
  end

  def siu_complaint_bases
    names = ["Unreasonable delay", "Not properly investigated"]
    @siu_complaint_bases ||= names.collect{|name| FactoryBot.create(:siu_complaint_basis, :name => name) }
  end

  def create_agencies
    AGENCIES.each do |name,full_name|
      Agency.create(:name => name, :full_name => full_name)
    end
  end
end
