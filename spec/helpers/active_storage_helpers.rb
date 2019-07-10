require 'rspec/core/shared_context'
module ActiveStorageHelpers
  def storage_dir
    Dir.new storage_path
  end

  def storage_path
    Rails.configuration.active_storage.service_configurations["test"]["root"]
  end

  def stored_files_count
    Dir.glob( Pathname(storage_path).join("**/*")).length
  end
end
