require 'rspec/core/shared_context'

module MediaSetupHelper
  extend RSpec::Core::SharedContext
  def setup_database(type)
    setup_areas
    if type == :media_appearance_with_file
      FactoryBot.create(:media_appearance,
                        :with_performance_indicators,
                        :hr_area,
                        :file,
                        :reminders=>[] )
    elsif type == :media_appearance_with_link
      FactoryBot.create(:media_appearance,
                         :with_performance_indicators,
                         :hr_area,
                         :article_link => example_dot_com,
                         :reminders=>[] )
    else
      FactoryBot.create(:media_appearance,
                         :with_performance_indicators,
                         :hr_area,
                         :reminders=>[] )
    end
    add_reminder
  end

  def add_a_second_article
    FactoryBot.create(:media_appearance,
                       :hr_area,
                       :reminders=>[] )
  end

  def add_reminder
    ma = MediaAppearance.first
    ma.reminders << FactoryBot.create(:reminder, :reminder_type => 'weekly', :text => "don't forget the fruit gums mum", :user => User.first)
    ma.save
  end

  def setup_articles
    FactoryBot.create(:media_appearance)
  end

  def setup_areas
    areas = ["Human Rights", "Good Governance", "Special Investigations Unit", "Corporate Services"]
    human_rights_subareas = ["Violation", "Education activities", "Office reports", "Universal periodic review", "CEDAW", "CRC", "CRPD"]
    good_governance_subareas = ["Violation", "Office report", "Office consultations"]

    areas.each do |a|
      MediaIssueArea.create(:name => a) unless MediaIssueArea.where(:name => a).exists?
    end

    human_rights_id = MediaIssueArea.where(:name => "Human Rights").first.id
    human_rights_subareas.each do |hrsa|
      MediaIssueSubarea.create(:name => hrsa, :area_id => human_rights_id) unless MediaIssueSubarea.where(:name => hrsa, :area_id => human_rights_id).exists?
    end

    good_governance_id = Area.where(:name => "Good Governance").first.id
    good_governance_subareas.each do |ggsa|
      MediaIssueSubarea.create(:name => ggsa, :area_id => good_governance_id) unless MediaIssueSubarea.where(:name => ggsa, :area_id => good_governance_id).exists?
    end
  end

  def setup_complaint_areas
    areas = ["Bish", "Bash", "Bosh"]
    human_rights_subareas = ["Hello", "World"]
    good_governance_subareas = ["Good", "Times", "Roll"]

    areas.each do |a|
      ComplaintArea.create(:name => a) unless ComplaintArea.where(:name => a).exists?
    end

    human_rights_id = ComplaintArea.where(:name => "Bish").first.id
    human_rights_subareas.each do |hrsa|
      ComplaintSubarea.create(:name => hrsa, :area_id => human_rights_id) unless ComplaintSubarea.where(:name => hrsa, :area_id => human_rights_id).exists?
    end

    good_governance_id = Area.where(:name => "Bash").first.id
    good_governance_subareas.each do |ggsa|
      ComplaintSubarea.create(:name => ggsa, :area_id => good_governance_id) unless ComplaintSubarea.where(:name => ggsa, :area_id => good_governance_id).exists?
    end
  end

  def setup_file_constraints
    SiteConfig['media_appearance.filetypes'] = ['pdf']
    SiteConfig['media_appearance.filesize'] = 3
  end

  def setup_strategic_plan
    sp = StrategicPlan.create(:created_at => 6.months.ago.to_date, :title => "a plan for the millenium")
    spl = StrategicPriority.create(:strategic_plan_id => sp.id, :priority_level => 1, :description => "Gonna do things betta")
    pr = PlannedResult.create(:strategic_priority_id => spl.id, :description => "Something profound")
    o = Outcome.create(:planned_result_id => pr.id, :description => "ultimate enlightenment")
    a1 = Activity.create(:description => "Smarter thinking", :outcome_id => o.id)
    3.times do
      PerformanceIndicator.create(:description => Faker::Lorem.words(3).join(" "), :target => "90%", :activity_id => a1.id)
    end
    a2 = Activity.create(:description => "Public outreach", :outcome_id => o.id)
    3.times do
      PerformanceIndicator.create(:description => Faker::Lorem.words(3).join(" "), :target => "90%", :activity_id => a2.id)
    end
    a3 = Activity.create(:description => "Media coverage", :outcome_id => o.id)
    3.times do
      PerformanceIndicator.create(:description => Faker::Lorem.words(3).join(" "), :target => "90%", :activity_id => a3.id)
    end
  end
end
