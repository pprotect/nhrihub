require 'rspec/core/shared_context'

module AreaSubareaAdminCommonHelpers
  extend RSpec::Core::SharedContext

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

