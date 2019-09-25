require 'rspec/core/shared_context'

module AdvisoryCouncilIssueSetupHelper
  extend RSpec::Core::SharedContext
  def setup_database(type = :advisory_council_issue_with_file)
    setup_areas
    if type == :advisory_council_issue_with_file
      FactoryBot.create(:advisory_council_issue,
                         :hr_subareas,
                         :gg_mandate,
                         :file,
                         :reminders=>[] )
    elsif type == :advisory_council_issue_with_link
      FactoryBot.create(:advisory_council_issue,
                         :hr_subareas,
                         :gg_mandate,
                         :link,
                         :reminders=>[] )
    else
      FactoryBot.create(:advisory_council_issue,
                         :hr_subareas,
                         :gg_mandate,
                         :reminders=>[] )
    end
  end

  def add_a_second_article
    FactoryBot.create(:advisory_council_issue,
                       :hr_subareas,
                       :gg_mandate,
                       :reminders=>[] )
  end

  def add_reminder
    issue = Nhri::AdvisoryCouncil::AdvisoryCouncilIssue.first
    issue.reminders << FactoryBot.create(:reminder, :reminder_type => 'weekly', :text => "don't forget the fruit gums mum", :users => [User.first])
    issue.save
  end

  def setup_articles
    FactoryBot.create(:advisory_council_issue)
  end

  def setup_areas
    areas = Area::DefaultNames
    human_rights_subareas = Subarea::DefaultNames[:"Human Rights"]
    good_governance_subareas = Subarea::DefaultNames[:"Good Governance"]

    areas.each do |a|
      Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.create(:name => a) unless Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => a).exists?
    end

    human_rights_id = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => "Human Rights").first.id
    human_rights_subareas.each do |hrsa|
      Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.create(:name => hrsa, :area_id => human_rights_id) unless Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.where(:name => hrsa, :area_id => human_rights_id).exists?
    end

    good_governance_id = Nhri::AdvisoryCouncil::AdvisoryCouncilIssueArea.where(:name => "Good Governance").first.id
    good_governance_subareas.each do |ggsa|
      Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.create(:name => ggsa, :area_id => good_governance_id) unless Nhri::AdvisoryCouncil::AdvisoryCouncilIssueSubarea.where(:name => ggsa, :area_id => good_governance_id).exists?
    end

    Mandate::DefaultNames.each do |name|
      Mandate.find_or_create_by(name: name)
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
    SiteConfig['nhri.advisory_council_issue.filetypes'] = ['pdf']
    SiteConfig['nhri.advisory_council_issue.filesize'] = 3
  end
end
