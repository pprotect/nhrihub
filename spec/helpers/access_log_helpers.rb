require 'rspec/core/shared_context'
require 'ie_remote_detector'

module AccessLogHelpers
  extend RSpec::Core::SharedContext

  def access_event
    AccessEvent.unscoped.last
  end
end
