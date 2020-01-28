class AddCloseMemoToStatusChange < ActiveRecord::Migration[6.0]
  def change
    add_column :status_changes, :close_memo, :string
  end
end
