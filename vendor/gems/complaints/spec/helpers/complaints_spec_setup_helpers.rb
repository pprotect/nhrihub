require 'rspec/core/shared_context'

module ComplaintsSpecSetupHelpers
  extend RSpec::Core::SharedContext

  def complete_required_fields(complaint_type)
    send("complete_#{complaint_type}_complaint_required_fields")
  end

  def complete_own_motion_complaint_required_fields
    page.find('#initiating_office_select').click
    sleep(0.2) # javascript
    page.find(:xpath, ".//li[./a/div/text()='Gauteng']")
    page.find('#initiating_office_select').click

    page.find('#initiating_branch_select').click
    sleep(0.2) # javascript
    page.find(:xpath, ".//li[contains(./a/div/text(),'Administrative Justice')]")
    page.find('#initiating_branch_select').click

    #Subject/beneficiary
    fill_in('firstName', :with => "Norman")
    fill_in('lastName', :with => "Normal")
    fill_in('postal_address', :with => 'abcd')
    fill_in('physical_address', :with => 'abcd')
    fill_in('city', :with => "Normaltown")
    fill_in('province', :with => 'wtf')
    fill_in('postal_code', :with => '1234')
    fill_in('email', :with => 'norm@acme.com')
    fill_in('home_phone', :with => '(132) 887-2389')
    fill_in('cell_phone', :with => '(132) 887-2389')
    fill_in('fax', :with => '(132) 887-2389')
    choose('Mail')

    fill_in('complaint_details', :with => "a long story about lots of stuff")
    choose('Special Investigations Unit')
    choose('complained_to_subject_agency_yes')
    check_subarea(:good_governance, "Delayed action")
    #select(User.admin.first.first_last_name, :from => "assignee")
  end

  def complete_organization_complaint_required_fields
    fill_in('organization_name', :with => "Acme Corp.")
    fill_in('contact_first_name', :with => "Norman")
    fill_in('contact_last_name', :with => "Normal")
    fill_in('postal_address', :with => 'abcd')
    fill_in('physical_address', :with => 'abcd')
    fill_in('city', :with => "Normaltown")
    fill_in('province', :with => 'wtf')
    fill_in('postal_code', :with => '1234')
    fill_in('contact_email', :with => 'norm@acme.com')
    fill_in('contact_phone', :with => '(132) 887-2389')
    fill_in('contact_fax', :with => '(132) 887-2389')
    choose('Mail')
    fill_in('complaint_details', :with => "a long story about lots of stuff")
    choose('Special Investigations Unit')
    choose('complained_to_subject_agency_yes')
    check_subarea(:good_governance, "Delayed action")
    #select(User.admin.first.first_last_name, :from => "assignee")
  end

  def complete_individual_complaint_required_fields
    fill_in('lastName', :with => "Normal")
    fill_in('firstName', :with => "Norman")
    fill_in('dob', :with => "08/09/1950")
    fill_in('city', :with => "Normaltown")
    fill_in('postal_code', :with => '1234')
    fill_in('province', :with => 'wtf')
    choose('Mail')
    fill_in('postal_address', :with => 'abcd')
    fill_in('complaint_details', :with => "a long story about lots of stuff")
    choose('Special Investigations Unit')
    choose('complained_to_subject_agency_yes')
    check_subarea(:good_governance, "Delayed action")
    #select(User.admin.first.first_last_name, :from => "assignee")
  end

  def populate_database(type)
    create_offices
    create_complaint_areas
    create_agencies
    create_staff
    create_complaint_statuses
    populate_areas_subareas
    user = User.where(:login => 'admin').first
    staff_user = User.where(:login => 'staff').first
    FactoryBot.create( type, :registered,
                      :assigned_to => [user, staff_user],
                      :date_received => DateTime.now.advance(:days => -100),
                      :city => Faker::Address.city,
                      :home_phone => Faker::PhoneNumber.phone_number,
                      :dob => "19/08/1950",
                      :email => "bish@bash.com",
                      :complaint_subareas => gg_subareas + hr_subareas + siu_subareas,
                      :desired_outcome => Faker::Lorem.sentence,
                      :details => Faker::Lorem.sentence,
                      :complaint_documents => complaint_docs,
                      :complaint_area_id => _complaint_area_id,
                      :agencies => _agencies,
                      :communications => _communications,
                      :organization_name => "Acme Corp",
                      :organization_registration_number => "12341234")
    FactoryBot.create( type, :closed,
                      :assigned_to => [user, staff_user],
                      :date_received => DateTime.now.advance(:days => -100),
                      :city => Faker::Address.city,
                      :home_phone => Faker::PhoneNumber.phone_number,
                      :dob => "19/08/1950",
                      :email => "foo@bash.com",
                      :complaint_subareas => hr_subareas,
                      :desired_outcome => Faker::Lorem.sentence,
                      :details => Faker::Lorem.sentence,
                      :complaint_documents => complaint_docs,
                      :complaint_area_id => _complaint_area_id,
                      :agencies => _agencies,
                      :communications => _communications,
                      :organization_name => Faker::Company.name,
                      :organization_registration_number => "56785678")
    set_file_defaults
  end

  def create_offices
    STAFF.group_by{|s| s[:group]}.each do |office_group,offices|
      group = OfficeGroup.find_or_create_by(:name => office_group.titlecase) unless office_group.nil?
      offices.map{|o| o[:office]}.uniq.each do |oname|
        if group&.name =~ /provinc/i
          province = Province.find_or_create_by(:name => oname)
          Office.find_or_create_by(:office_group_id => group&.id, :province_id => province&.id )
        else
          Office.find_or_create_by(:name => oname, :office_group_id => group&.id)
        end
      end
    end
  end

  def create_complaints
    admin = User.where(:login => 'admin').first
    assignees = [admin, admin]
    FactoryBot.create(:complaint, :open, :assigned_to => assignees,
                      #:case_reference => "c12-22",
                      :complaint_area => hr_area,
                      :complaint_subareas => hr_subareas,
                      :agencies => [Agency.first]
                     )
    FactoryBot.create(:complaint, :open, :assigned_to => assignees,
                      #:case_reference => "c12-33",
                      :complaint_area => hr_area,
                      :complaint_subareas => hr_subareas,
                      :agencies => [Agency.first]
                     )
    @complaint = FactoryBot.create(:complaint, :open, :assigned_to => assignees,
                                   #:case_reference => "c12-55",
                                   :complaint_area => hr_area,
                                   :complaint_subareas => hr_subareas,
                                   :agencies => [Agency.first]
                                  )
  end

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

  def create_complaint_areas
    ComplaintArea::DefaultNames.each do |name|
      FactoryBot.create(:complaint_area, :name => name)
    end
  end

  def create_subareas
    hr_subareas
    gg_subareas
    siu_subareas
    cc_subareas
  end

  def create_complaint_statuses
    ComplaintStatus::Names.each do |status_name|
      sym = status_name.downcase.to_sym
      FactoryBot.create(:complaint_status, sym)
    end
  end

  def _communications
    [ FactoryBot.create(:communication) ]
  end

  def _complaint_area_id
    ComplaintArea.find_or_create_by( :name => "Human Rights").id
  end

  def _agencies
    [ Agency.find_by(:name => 'SAA') ]
  end

  def complaint_docs
    Array.new(2) { FactoryBot.create(:complaint_document) }
  end

  def create_agencies
    AGENCIES.each do |name,full_name|
      Agency.create(:name => name, :full_name => full_name)
    end
  end

  def gg_area
    ComplaintArea.find_or_create_by( :name => "Good Governance")
  end

  def gg_subareas
    ["Delayed action", "Failure to act", "Contrary to Law", "Oppressive", "Private"].collect do |name|
      ComplaintSubarea.find_or_create_by(name: name, area_id: gg_area.id)
    end
  end

  def hr_area
    ComplaintArea.find_or_create_by(:name => "Human Rights")
  end

  def hr_subareas
    ["CAT", "ICESCR"].collect do |name|
      ComplaintSubarea.find_or_create_by(name: name, area_id: hr_area.id)
    end
  end

  def siu_area
    ComplaintArea.find_or_create_by(:name => "Special Investigations Unit")
  end

  def cc_area
    ComplaintArea.find_or_create_by(:name => "Corporate Services")
  end

  def siu_subareas
    ["Unreasonable delay", "Not properly investigated"].collect do |name|
      ComplaintSubarea.find_or_create_by(name: name, area_id: siu_area.id)
    end
  end

  def cc_subareas
    ["Bish", "Bash", "Bosh"].collect do |name|
      ComplaintSubarea.find_or_create_by(name: name, area_id: cc_area.id)
    end
  end

  def populate_areas_subareas
    gg_subareas
    hr_subareas
    siu_subareas
  end
end
