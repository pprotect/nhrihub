class AddAssignerToAssigns < ActiveRecord::Migration[6.0]
  def change
    add_column :assigns, :assigner_id, :integer
  end
end
