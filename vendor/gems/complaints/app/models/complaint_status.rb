class ComplaintStatus < ActiveRecord::Base
  has_many :status_changes
  StatusNames = ["Open", "Closed", "Under Evaluation"]

  StatusNames.each do |status_name|
    scope status_name.downcase.gsub(/\s/,'_').to_sym, -> { where(name: status_name) }
  end
end
