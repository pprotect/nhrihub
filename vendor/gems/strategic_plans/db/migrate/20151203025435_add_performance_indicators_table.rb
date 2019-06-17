class AddPerformanceIndicatorsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :performance_indicators, :force => true do |t|
      t.integer :activity_id
      t.text :description
      t.text :target
      t.timestamps
    end

    remove_column :activities,:performance_indicator, :text
    remove_column :activities,:target, :text
  end
end
