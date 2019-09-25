class AddMandateIdToAdvisoryIssue < ActiveRecord::Migration[6.0]
  def change
    add_column :advisory_council_issues, :mandate_id, :integer
  end
end
