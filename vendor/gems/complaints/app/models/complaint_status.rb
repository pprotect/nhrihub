class ComplaintStatus < ActiveRecord::Base
  has_many :status_changes
  Names = ["Open", "Closed", "Under Evaluation"]

  Names.each do |status_name|
    scope status_name.downcase.gsub(/\s/,'_').to_sym, -> { where(name: status_name) }
  end
end
