class ChangeComplainantAltIdTypeDefault < ActiveRecord::Migration[6.0]
  def change
    change_column :complainants, :alt_id_type, :integer, limit: 2, default: 0
  end
end
