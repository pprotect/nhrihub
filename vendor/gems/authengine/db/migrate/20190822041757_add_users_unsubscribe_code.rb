class AddUsersUnsubscribeCode < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :unsubscribe_code, :string, limit: 40
  end
end
