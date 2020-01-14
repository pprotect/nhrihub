require 'rspec/core/shared_context'

module OfficeGroupOfficeAdminCommonHelpers
  extend RSpec::Core::SharedContext

  def create_default_office_groups
    STAFF.group_by{|s| s[:group]}.each do |office_group,offices|
      group = OfficeGroup.create(:name => office_group.titlecase) unless office_group.nil?
      offices.map{|o| o[:office]}.uniq.each do |oname|
        Office.create(:name => oname, :office_group_id => group&.id)
      end
    end
  end

  def open_accordion_for_office_group(text)
    target_office_group = office_group_called(text)
    target_office_group.find('#offices_link').click
    accordion_element = target_office_group.find(:xpath, "./parent::*/div[contains(@class,'collapse')]")['id']
    wait_for_accordion("#"+accordion_element)
  end

  def office_group_called(text)
    page.find('.row.office_group', :text => text)
  end

  def offices
    page.all('.office .name').map(&:text)
  end

  def click_delete_for(office_group, office=nil)
    if office
      open_office_panel_for_office_group(office_group)
      page.find(:xpath, ".//div[@class='panel panel-default'][.//div[contains(text(),'#{office_group}')]]//div[@class='row office'][./div[contains(text(),'#{office}')]]//a[contains(text(),'Delete')]").click
    else
      page.find(:xpath, ".//div[@class='row office_group panel-heading'][./div[contains(text(),'#{office_group}')]]").find('.delete_office_group').click
    end
  end

  def open_office_panel_for_office_group(office_group)
    page.find(:xpath, ".//div[@class='panel panel-default'][.//div[contains(text(),'#{office_group}')]]//a[@id='offices_link']").click
    sleep(0.3)
  end
end

