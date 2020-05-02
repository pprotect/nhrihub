require 'rspec/core/shared_context'

module SingleComplaintCommunicationsSpecHelpers
  extend RSpec::Core::SharedContext

  def open_communications_modal
    page.all('.fa-comments-o')[0].click
  end
end
