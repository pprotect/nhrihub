class CreateCaseReference < ActiveRecord::Migration[6.0]
  def change
    create_table :case_references do |t|
      t.integer :year
      t.integer :sequence
      t.integer :complaint_id
      t.timestamps
    end
  end
end
