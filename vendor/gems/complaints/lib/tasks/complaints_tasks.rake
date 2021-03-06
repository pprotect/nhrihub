namespace :complaints do
  desc "populates all complaint-related tables"
  task :populate => [:populate_complaints]

  task :depopulate => :environment do
    Complaint.destroy_all
    Complainant.destroy_all
  end

  desc "populates DemocracySupportingStateInstitution"
  task :populate_democracy_institutions => :environment do
    DemocracySupportingStateInstitutions.each do |dssi|
      DemocracySupportingStateInstitution.create(name: dssi)
    end
  end

  desc "populates NationalGovernmentInstitutions"
  task :populate_gov_institutions => :environment do
    NationalGovernmentInstitutions.each do |ngi|
      NationalGovernmentInstitution.create(name: ngi)
    end
  end

  desc "populates NationalGovernmentAgencies"
  task :populate_gov_agencies => :environment do
    NationalGovernmentAgencies.each do |nga|
      NationalGovernmentAgency.create(name: nga)
    end
  end

  desc "populates complaints"
  task :populate_complaints => [ :populate_statuses, :populate_areas_subareas, 'populate_legislations', 'projects:populate_mandates', 'projects:populate_agnc', "populate_gov_agencies", "populate_gov_institutions", "populate_democracy_institutions", "complaints:depopulate"] do
    n = 50
    n.times do |i|
      complaint = [:individual_complaint, :own_motion_complaint, :organization_complaint].sample
      complaint = FactoryBot.create(complaint, :with_associations, :with_assignees, :with_document, :with_comm, :with_reminders, :with_notes)
      n -= 1
    end
  end

  desc "populates legislations table"
  task :populate_legislations => :environment do
    Legislation.destroy_all
    LEGISLATIONS.each do |legislation|
      Legislation.create(short_name: legislation[:short_name], full_name: legislation[:full_name])
    end
  end

  desc "populates status table"
  task :populate_statuses => :environment do
    ComplaintStatus.destroy_all
    ComplaintStatus::Names.each do |name|
      ComplaintStatus.create(:name => name)
    end
  end

  desc "populates complaint areas and subareas"
  task :populate_areas_subareas => :environment do
    ComplaintArea.destroy_all
    ComplaintSubarea.destroy_all
    Subarea::DefaultNames.each do |name,subareas|
      area = FactoryBot.create(:complaint_area, name: name)

      subareas.each do |subarea_name|
        FactoryBot.create(:complaint_subarea, area_id: area.id, name: subarea_name)
      end
    end
  end

  desc "populates offices and office_groups"
  task :populate_office_office_groups => :environment do
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

  desc "populates the 9 provinces of South Africa"
  task :populate_provinces => :environment do
    provinces = ["Gauteng", "Mpumalanga", "North West", "Western Cape",
                 "Kwa-Zulu Natal", "Limpopo", "Free State", "Northern Cape",
                 "Eastern Cape"]
    provinces.each do |province|
      Province.find_or_create_by(:name => province)
    end
  end
end
