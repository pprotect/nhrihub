class AddTypeToAreasSubareas < ActiveRecord::Migration[6.0]
  def change
    add_column :areas, :type, :string
    add_column :subareas, :type, :string
    Area.update_all(type: 'MediaIssueArea')
    Area.update_all(type: 'MediaIssueSubarea')
  end
end
