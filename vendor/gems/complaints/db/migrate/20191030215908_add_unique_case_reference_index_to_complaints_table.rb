class AddUniqueCaseReferenceIndexToComplaintsTable < ActiveRecord::Migration[6.0]
  def up
    add_index :complaints, :case_reference, unique: true
    unless column_exists? :complaints, :case_reference_alt
      add_column :complaints, :case_reference_alt, :string
    end
    Complaint.all.each do |complaint|
      complaint.update_attribute(:case_reference_alt, complaint.case_reference)
      case_ref = complaint.case_reference_alt
      year, sequence = case_ref[1,8].split('-').map(&:to_i)
      case_reference = "--- !ruby/object:CaseReference\nyear: #{year}\nsequence: #{sequence}\n"
      complaint.update_attribute(:case_reference, case_reference)
    end
  end

  def down
    remove_index :complaints, :case_reference
    Complaint.all.each do |complaint|
      case_ref = complaint.case_reference_alt
      year, sequence = case_ref[1,8].split('-').map(&:to_i)
      complaint.update_attribute(:case_reference, "C#{year}-#{sequence}")
    end
  end
end
