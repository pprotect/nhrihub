
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

end
