class AddPasswordExpiryDateToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :password_expiry_date, :datetime
    add_column :users, :password_expiry_token, :string
  end
end
