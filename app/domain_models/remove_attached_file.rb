require 'active_support/concern'
# use with ActiveStorage to remove the stored file when
# a new file is uploaded or user wishes to delete the attached file
module RemoveAttachedFile
  extend ActiveSupport::Concern

  # remove old files when a new one is uploaded
  def file=(file)
    if file.is_a? ActionDispatch::Http::UploadedFile
      self.file.purge
    end
    super
  end

  # user requests to delete old file, with no new file uploaded
  def remove_file=(val)
    file.purge if val
  end

end
