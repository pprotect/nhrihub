class Legislation < ActiveRecord::Base
  has_many :complaint_legislations
  has_many :complaints, through: :complaint_legislations

  def as_json(options={})
    super(methods: [:name, :delete_allowed], only: [:id, :short_name, :full_name])
  end

  def name
    [short_name, full_name].join(', ')
  end

  def delete_allowed
    complaints.count.zero?
  end
end
