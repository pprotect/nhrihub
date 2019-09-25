namespace :projects do
  desc "populates all projects-related tables"
  task :populate => ["projects:populate_mandates", "projects:populate_areas_subareas", "projects:populate_projects"]

  desc "depopulates projects, leaving mandates untouched"
  task :depopulate => :environment do
    Project.destroy_all
  end

  desc "populates the projects table"
  task "populate_projects" => "projects:depopulate" do
    5.times do
      FactoryBot.create(:project, :with_reminders, :with_performance_indicators, :with_documents, :with_mandate, :with_subareas)
    end
  end

  desc "populates the mandates table"
  task :populate_mandates => :environment do
    ["good_governance", "human_rights", "special_investigations_unit", "strategic_plan"].each do |key|
      Mandate.find_or_create_by(:key => key)
    end
  end

  desc "populates areas and subareas"
  task :populate_areas_subareas => :environment do
    ProjectSubarea.destroy_all
    ProjectArea.destroy_all

    Area::DefaultNames.each do |name|
      area = ProjectArea.create(:name => name)
      ProjectSubarea::DefaultNames["#{name}"].each do |subarea_name|
        ProjectSubarea.create(:name => subarea_name, :area_id => area.id)
      end
    end
  end

  desc "populates agencies"
  task :populate_agnc => :environment do
    Agency.destroy_all
    # AGENCIES defined in lib/constants
    agencies = AGENCIES.each do |short,full|
      Agency.create(:name => short, :full_name => full)
    end
  end

end
