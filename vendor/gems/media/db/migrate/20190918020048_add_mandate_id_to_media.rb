class AddMandateIdToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media_appearances, :mandate_id, :integer
  end
end
