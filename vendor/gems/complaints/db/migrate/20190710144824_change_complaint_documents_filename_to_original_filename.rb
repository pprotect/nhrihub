class ChangeComplaintDocumentsFilenameToOriginalFilename < ActiveRecord::Migration[6.0]
  def change
    rename_column :complaint_documents, :filename, :original_filename
  end
end
