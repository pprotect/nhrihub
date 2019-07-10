class ChangeCommunicationDocumentsFilenameToOriginalFilename < ActiveRecord::Migration[6.0]
  def change
    rename_column :communication_documents, :filename, :original_filename
  end
end
