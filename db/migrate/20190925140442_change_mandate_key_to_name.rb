class ChangeMandateKeyToName < ActiveRecord::Migration[6.0]
  def up
    rename_column :mandates, :key, :name
    Mandate.all.each do |m|
      m.update_attributes(:name => m.name.humanize.titlecase)
    end
  end

  def down
    rename_column :mandates, :name, :key
    Mandate.all.each do |m|
      m.update_attributes(:key => m.key.titlecase.unspaced.underscore)
    end
  end
end
