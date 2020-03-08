class AddFailedLoginCountToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :failed_login_count, :integer, limit: 1, default: 0
  end
end
