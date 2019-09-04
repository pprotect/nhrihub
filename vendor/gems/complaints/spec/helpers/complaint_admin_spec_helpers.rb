require 'rspec/core/shared_context'

module ComplaintAdminSpecHelpers
  extend RSpec::Core::SharedContext

  before do
    create_default_areas
    visit complaint_admin_path('en')
  end

  def create_default_areas
    ["Human Rights", "Good Governance", "Special Investigations Unit", "Corporate Services"].each do |a|
      ComplaintArea.create(:name => a)
    end
    human_rights_id = ComplaintArea.where(:name => 'Human Rights').first.id
    [{:area_id => human_rights_id, :name => "Violation", :full_name => "Violation"},
    {:area_id => human_rights_id, :name => "Education activities", :full_name => "Education activities"},
    {:area_id => human_rights_id, :name => "Office reports", :full_name => "Office reports"},
    {:area_id => human_rights_id, :name => "Universal periodic review", :full_name => "Universal periodic review"},
    {:area_id => human_rights_id, :name => "CEDAW", :full_name => "Convention on the Elimination of All Forms of Discrimination against Women"},
    {:area_id => human_rights_id, :name => "CRC", :full_name => "Convention on the Rights of the Child"},
    {:area_id => human_rights_id, :name => "CRPD", :full_name => "Convention on the Rights of Persons with Disabilities"}].each do |attrs|
      ComplaintSubarea.create(attrs)
    end

    good_governance_id = ComplaintArea.where(:name => "Good Governance").first.id

    [{:area_id => good_governance_id, :name => "Violation", :full_name => "Violation"},
    {:area_id => good_governance_id, :name => "Office report", :full_name => "Office report"},
    {:area_id => good_governance_id, :name => "Office consultations", :full_name => "Office consultations"}].each do |attrs|
      ComplaintSubarea.create(attrs)
    end
  end

  #def new_siu_complaint_subarea_button
    #page.find('#new_siu_subarea button')
  #end

  #def new_gg_complaint_subarea_button
    #page.find('#new_good_governance_subarea button')
  #end

  #def new_strategic_plan_complaint_subarea_button
    #page.find('#new_strategic_plan_subarea button')
  #end

  #def delete_complaint_subarea(text)
    #page.find(:xpath, ".//tr[contains(td,'#{text}')]//a")
  #end
end
