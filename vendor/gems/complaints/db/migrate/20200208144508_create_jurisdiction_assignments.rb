class CreateJurisdictionAssignments < ActiveRecord::Migration[6.0]
  def change
    create_table :jurisdiction_assignments do |t|
      t.integer :user_id
      t.integer :branch_id
      t.integer :complaint_id
      t.timestamps
    end
  end
end
