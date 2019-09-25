class AddTypeToAreasSubareas < ActiveRecord::Migration[6.0]
  def change
    add_column :areas, :type, :string
    add_column :subareas, :type, :string

    rename_table :issue_areas, :advisory_council_issue_issue_areas
    rename_table :issue_subareas, :advisory_council_issue_issue_subareas


    Area.update_all(type: 'MediaArea')
    Area.update_all(type: 'MediaSubarea')
  end
end
