require 'rspec/core/shared_context'
require 'ie_remote_detector'

module AccessLogHelpers
  extend RSpec::Core::SharedContext

  def access_log_message
    File.readlines(AccessLog::LogFile)[-1]
  end
end
