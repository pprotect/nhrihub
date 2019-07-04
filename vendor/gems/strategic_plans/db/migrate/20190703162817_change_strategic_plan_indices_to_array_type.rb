class ChangeStrategicPlanIndicesToArrayType < ActiveRecord::Migration[5.2]
  def up
    remove_column :planned_results, :index
    remove_column :outcomes, :index
    remove_column :activities, :index
    remove_column :performance_indicators, :index
    add_column :planned_results, :index, :integer, :array => true
    add_column :outcomes, :index, :integer, :array => true
    add_column :activities, :index, :integer, :array => true
    add_column :performance_indicators, :index, :integer, :array => true
  end

  def down
    change_column :planned_results, :index, :string, :limit => 10, using: "(array_to_string(index,'.'))"
    change_column :outcomes, :index, :string, :limit => 10, using: "(array_to_string(index,'.'))"
    change_column :activities, :index, :string, :limit => 10, using: "(array_to_string(index,'.'))"
    change_column :performance_indicators, :index, :string, :limit => 10, using: "(array_to_string(index,'.'))"
  end
end
