class ChangeProjectDocumentsFilenameToOriginalFilename < ActiveRecord::Migration[6.0]
  def change
    rename_column :project_documents, :filename, :original_filename
  end
end
