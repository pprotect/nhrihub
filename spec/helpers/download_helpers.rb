require 'rspec/core/shared_context'
module DownloadHelpers
  extend RSpec::Core::SharedContext
  PATH = File.expand_path('../../../tmp/downloaded_files', __FILE__)
  TIMEOUT = 30 # for unknown reasons, it downloads sometimes pause midway, taking way too long

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.1 until downloaded?
    end
  rescue Timeout::Error
    raise "download didn't happen"
  end

  def downloaded?
    !downloading? && downloaded_files.any?
  end

  def downloading?
    downloaded_files.grep(/\.crdownload$/).any?
  end

  def downloaded_files
    Dir[PATH+"/*"]
  end

  def downloaded_file
    wait_for_download
    filename = downloaded_files.first.split("/").last
  end


  def clear_downloaded_files
    FileUtils.rm_f(downloaded_files)
  end

  before do
    clear_downloaded_files
  end

  after do
    clear_downloaded_files
  end
end
