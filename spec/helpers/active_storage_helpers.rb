require 'rspec/core/shared_context'
module ActiveStorageHelpers
  def storage_path
    Pathname(Rails.configuration.active_storage.service_configurations["test"]["root"])
  end

  def stored_files_count
    Dir.glob( storage_path.join("**/*")).select{|f| File.file? f }.length
  end

  def stored_file_path(object)
    key = object.reload.file.attachment.blob.key
    storage_path.join(key)
  end
end
