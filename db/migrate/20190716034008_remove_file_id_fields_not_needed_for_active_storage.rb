class RemoveFileIdFieldsNotNeededForActiveStorage < ActiveRecord::Migration[6.0]
  def change
    remove_column :advisory_council_documents, :file_id, :string, limit: 255
    remove_column :advisory_council_issues, :file_id, :string, limit: 255
    remove_column :communication_documents, :file_id, :string, limit: 255
    remove_column :complaint_documents, :file_id, :string, limit: 255
    remove_column :file_monitors, :file_id, :string, limit: 255
    remove_column :icc_reference_documents, :file_id, :string, limit: 255
    remove_column :internal_documents, :file_id, :string, limit: 255
    remove_column :media_appearances, :file_id, :string, limit: 255
    remove_column :project_documents, :file_id, :string, limit: 255
  end
end
