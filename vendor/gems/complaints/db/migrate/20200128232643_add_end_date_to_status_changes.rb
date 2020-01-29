class AddEndDateToStatusChanges < ActiveRecord::Migration[6.0]
  def change
    add_column :status_changes, :end_date, :datetime
  end
end
