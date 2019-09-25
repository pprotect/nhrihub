require 'rspec/core/shared_context'
require 'projects_spec_setup_helpers'

module ProjectsSpecHelpers
  extend RSpec::Core::SharedContext
  include ProjectsSpecSetupHelpers

  def add_a_performance_indicator
    select_performance_indicators.click
    page.all("li.performance_indicator a").first.click
    select_performance_indicators.click
    PerformanceIndicator.first
  end

  def add_a_unique_performance_indicator
    select_performance_indicators.click
    page.all("li.performance_indicator a").last.click
    PerformanceIndicator.all.to_a.last
  end

  def click_the_download_icon
    page.all('#project_documents .project_document .fa-cloud-download')[0].click
  end

  def reset_permitted_filetypes
    page.execute_script("projects.set('permitted_filetypes',[])")
  end

  def set_permitted_filetypes
    page.execute_script("projects.set('permitted_filetypes',['anything'])")
  end

  def upload_file_path(filename)
    CapybaraRemote.upload_file_path(page,filename)
  end

  def upload_document
    upload_file_path('first_upload_file.pdf')
  end

  def big_upload_document
    upload_file_path('big_upload_file.pdf')
  end

  def upload_image
    upload_file_path('first_upload_image_file.png')
  end

  def single_item_selector
    "#projects .project"
  end

  def projects_count
    page.all(single_item_selector).count
  end
  alias_method :number_of_rendered_projects, :projects_count

  def number_of_all_projects
    page.all(single_item_selector, :visible => false).count
  end

  def add_project
    page.find('#add_project')
  end

  def save_project
    find('#save_project')
  end

  def cancel_project
    find('#cancel_project')
  end

  def first_project
    page.all('#projects .project')[0]
  end

  def last_project
    page.all('#projects .project')[1]
  end

  def areas
    find('#areas')
  end

  def edit_documents
    find('.documents .edit')
  end

  def subareas
    find('#subareas')
  end

  def good_governance_subareas
    subarea_names("Good Governance")
  end

  def human_rights_subareas
    subarea_names("Human Rights")
  end

  def check_subarea(area, subarea)
  area_key = area.gsub(/\s/,'').underscore
  checkbox = page.find("##{area_key}_subareas .subarea", :text => subarea).find('input')
  checkbox.click
  end

  def agencies
    all('#agencies').first
  end

  def conventions
    conventions_top = page.evaluate_script("$('#conventions').offset().top")
    page.execute_script("scrollTo(0,#{conventions_top})")
    all('#conventions').first
  end

  def new_project
    page.find('.new_project')
  end

  def expand_first_project
    sleep(0.5) # seems to be necessary in order for bootstrap collapse('show') to be called
    page.all('.project .actions #expand')[0].click
  end

  def expand_last_project
    sleep(0.5) # seems to be necessary in order for bootstrap collapse('show') to be called
    page.all('.project .actions #expand')[-1].click
  end

  def delete_project_icon
    page.all('.project .delete_icon')[0]
  end

  def delete_file
    scroll_to(page.all('#project_documents .project_document .delete_icon')[0])
  end

  def edit_save
    find('i.fa-check').click
    wait_for_ajax
  end

  def edit_first_project
    scroll_to(page.all('.project .icon .fa-pencil-square-o')[0])
  end

  def edit_last_project
    scroll_to(page.all('.project .icon .fa-pencil-square-o').last)
  end

  def select_performance_indicators
    # because it was off the page!
    coordinates = page.evaluate_script("$('.performance_indicator_select>a').offset()")
    top = coordinates["top"]
    top = top - 100
    page.execute_script("scrollTo(0,#{top})")
    page.find('.performance_indicator_select>a')
  end

  def performance_indicators
    find('.performance_indicators')
  end

  def performance_indicator_descriptions
    all('.performance_indicator').map(&:text)
  end

  def remove_first_indicator
    scroll_to(page.all('.selected_performance_indicator .remove')[0])
  end

  def remove_last_indicator
    scroll_to(page.all('.selected_performance_indicator .remove')[-1])
  end

  def uncheck_all_checkboxes
    sleep(0.3)
    page.
      all(:xpath, "//input[@type='checkbox']").
      each{|cb| scroll_to(cb); uncheck(cb["id"]) }
  end

  def edit_cancel
    find('#edit_cancel').click
  end

  def checkbox(id)
    find(:xpath, "//input[@type='checkbox'][@id='#{id}']")
  end

  def radio(id)
    find(:xpath, "//input[@type='radio'][@id='#{id}']")
  end

  def click_the_download_icon
    scroll_to(page.all("#projects .project .project_document .fa-cloud-download")[0]).click
  end

  def project_documents
    page.find('#project_documents')
  end

  private
  def subarea_names(area)
    all(:xpath, ".//div[@class='area'][contains(./div[@class='name'],'#{area}')]/div[contains(@class,'subareas')]/span[@class='subarea']").map(&:text)
  end
end
