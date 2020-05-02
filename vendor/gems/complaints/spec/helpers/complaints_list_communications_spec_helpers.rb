require 'rspec/core/shared_context'

module ComplaintsListCommunicationsSpecHelpers
  extend RSpec::Core::SharedContext

  def open_communications_modal
    page.find('.case_reference', :text => Complaint.first.case_reference) # hack to make sure the page is loaded and rendered
    page.all('#complaints .complaint .fa-comments-o')[0].click
  end
end

