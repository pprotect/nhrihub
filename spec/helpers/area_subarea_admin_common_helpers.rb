require 'rspec/core/shared_context'

module AreaSubareaAdminCommonHelpers
  extend RSpec::Core::SharedContext

  def create_default_areas
    ["Human Rights", "Good Governance", "Special Investigations Unit", "Corporate Services"].each do |a|
      area_model.create(:name => a)
    end
    human_rights_id = area_model.where(:name => 'Human Rights').first.id
    [{:area_id => human_rights_id, :name => "Violation", :full_name => "Violation"},
    {:area_id => human_rights_id, :name => "Education activities", :full_name => "Education activities"},
    {:area_id => human_rights_id, :name => "Office reports", :full_name => "Office reports"},
    {:area_id => human_rights_id, :name => "Universal periodic review", :full_name => "Universal periodic review"},
    {:area_id => human_rights_id, :name => "CEDAW", :full_name => "Convention on the Elimination of All Forms of Discrimination against Women"},
    {:area_id => human_rights_id, :name => "CRC", :full_name => "Convention on the Rights of the Child"},
    {:area_id => human_rights_id, :name => "CRPD", :full_name => "Convention on the Rights of Persons with Disabilities"}].each do |attrs|
      subarea_model.create(attrs)
    end

    good_governance_id = area_model.where(:name => "Good Governance").first.id

    [{:area_id => good_governance_id, :name => "Violation", :full_name => "Violation"},
    {:area_id => good_governance_id, :name => "Office report", :full_name => "Office report"},
    {:area_id => good_governance_id, :name => "Office consultations", :full_name => "Office consultations"}].each do |attrs|
      subarea_model.create(attrs)
    end
  end

  def open_accordion_for_area(text)
    target_area = area_called(text)
    target_area.find('#subareas_link').click
    accordion_element = target_area.find(:xpath, "./parent::*/div[contains(@class,'collapse')]")['id']
    wait_for_accordion("#"+accordion_element)
  end

  def area_called(text)
    page.find('.row.area', :text => text)
  end

  def subareas
    page.all('.subarea .name').map(&:text)
  end

  def click_delete_for(area, subarea=nil)
    if subarea
      open_subarea_panel_for_area(area)
      page.find(:xpath, ".//div[@class='panel panel-default'][.//div[contains(text(),'#{area}')]]//div[@class='row subarea'][./div[contains(text(),'#{subarea}')]]//a[contains(text(),'Delete')]").click
    else
      page.find(:xpath, ".//div[@class='row area panel-heading'][./div[contains(text(),'#{area}')]]").find('.delete_area').click
    end
  end

  def open_subarea_panel_for_area(area)
    page.find(:xpath, ".//div[@class='panel panel-default'][.//div[contains(text(),'#{area}')]]//a[@id='subareas_link']").click
    sleep(0.3)
  end
end

