namespace :media do
  desc "populates areas and subareas"
  task :populate_areas => :environment do
    areas = MediaArea::DefaultNames
    human_rights_subareas = MediaSubarea::DefaultNames[:"Human Rights"]
    good_governance_subareas = MediaSubarea::DefaultNames[:"Good Governance"]

    MediaArea.destroy_all
    MediaSubarea.destroy_all
    areas.each do |a|
      MediaArea.create(:name => a) unless MediaArea.where(:name => a).exists?
    end

    human_rights_id = MediaArea.where(:name => "Human Rights").first.id
    human_rights_subareas.each do |hrsa|
      MediaSubarea.create(:name => hrsa, :area_id => human_rights_id) unless MediaSubarea.where(:name => hrsa, :area_id => human_rights_id).exists?
    end

    good_governance_id = MediaArea.where(:name => "Good Governance").first.id
    good_governance_subareas.each do |ggsa|
      MediaSubarea.create(:name => ggsa, :area_id => good_governance_id) unless MediaSubarea.where(:name => ggsa, :area_id => good_governance_id).exists?
    end
  end

  desc "depopulates media table"
  task :depopulate => :environment do
    MediaAppearance.destroy_all
  end

  desc "populates media appearances with examples"
  task :populate_media => "media:depopulate" do
    20.times do
      ma = FactoryBot.create(:media_appearance, :with_reminders, :with_notes, :with_performance_indicators, [:file, :link].sample, *[:hr_area, :si_area, :gg_area, :hr_violation_subarea].sample(2))
      puts ma.area_subarea_ids
    end
  end

  desc "populate both media, including dependencies"
  task :populate => :environment do
    Rake::Task["strategic_plan:populate_sp"].invoke
    Rake::Task["media:populate_areas"].invoke
    Rake::Task["media:populate_media"].invoke
  end
end
