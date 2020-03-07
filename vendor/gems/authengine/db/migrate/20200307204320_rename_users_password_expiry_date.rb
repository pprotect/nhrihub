class RenameUsersPasswordExpiryDate < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :password_expiry_date, :password_start_date
  end
end
