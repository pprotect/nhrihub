class Legislation < ActiveRecord::Base
  has_many :complaint_legislations
  has_many :complaints, through: :complaint_legislations

  def delete_allowed
    complaints.count.zero?
  end
end
