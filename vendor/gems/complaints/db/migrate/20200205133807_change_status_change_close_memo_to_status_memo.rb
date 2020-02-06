class ChangeStatusChangeCloseMemoToStatusMemo < ActiveRecord::Migration[6.0]
  def change
    rename_column :status_changes, :close_memo, :status_memo
    add_column :status_changes, :status_memo_type, :integer, limit: 1, default: 0
  end
end
