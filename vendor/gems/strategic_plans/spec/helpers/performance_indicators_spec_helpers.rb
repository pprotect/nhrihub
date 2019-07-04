require 'rspec/core/shared_context'

module PerformanceIndicatorsSpecHelpers
  extend RSpec::Core::SharedContext
  def click_delete_icon
    page.find(performance_indicator_selector + "span.delete_icon").click
  end

  def first_performance_indicator_description
    page.all(performance_indicator_selector + ".description div.no_edit span:nth-of-type(1)")[0]
  end

  def performance_indicator_edit_cancel
    page.find('#edit_cancel')
  end

  def performance_indicator_selector
    ".table#planned_results .row.planned_result .row.outcome .row.activity .row.performance_indicator "
  end

  def edit_performance_indicator
    performance_indicator_description_field.first
  end

  def performance_indicator_description_field
    page.all(performance_indicator_selector + ".description textarea").select{|i| i['id'] && i['id'].match(/performance_indicator_\d_description/)}
  end

  def performance_indicator_target_field
    page.all(performance_indicator_selector + ".target textarea").select{|i| i['id'] && i['id'].match(/performance_indicator_\d_target/)}
  end

  def performance_indicator_save_icon
    page.find('#edit_save')
  end

  def save_performance_indicator
    page.find("i#create_save")
  end

  def add_performance_indicator
    page.find(".new_performance_indicator")
  end

  def cancel_performance_indicator_addition
    page.find('.new_performance_indicator_control #create_stop').click
  end

  def performance_indicator_indices
    page.evaluate_script("_(strategic_plan.findAllComponents('pi')).map(function(pi){return pi.get('index')})").map{|i| i.join('.') }
  end
end
