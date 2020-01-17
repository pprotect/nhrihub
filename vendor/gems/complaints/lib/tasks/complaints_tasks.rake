
namespace :complaints do
  desc "populates all complaint-related tables"
  task :populate => [:populate_complaints]

  task :depopulate => :environment do
    Complaint.destroy_all
  end

  desc "populates complaints"
  task :populate_complaints => [ :populate_statuses, :populate_areas_subareas, 'projects:populate_mandates', 'projects:populate_agnc', "complaints:depopulate"] do
    n = 50
    n.times do |i|
      complaint = FactoryBot.create(:complaint, :with_associations, :with_assignees, :with_document, :with_comm, :with_reminders, :with_notes, :case_reference => "C17-#{n-i}")
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
