require 'rspec/core/shared_context'

module AgencyAdminHelpers
  extend RSpec::Core::SharedContext
  def open_accordion(label)
    page.find('.panel-heading', exact_text: label).find('.fa-caret-right').click
  end

  def save_agency
    page.find('button#add_agency').click
    wait_for_ajax
  end

  def agencies_list
    page.all('.agency')
  end
end
