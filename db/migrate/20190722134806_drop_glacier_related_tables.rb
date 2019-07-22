class DropGlacierRelatedTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :glacier_archives
    drop_table :application_data_backups_glacier_file_archives
  end
end
