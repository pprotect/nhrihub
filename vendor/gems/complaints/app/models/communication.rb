class Communication < ActiveRecord::Base
  belongs_to :complaint, :touch => true
  belongs_to :user
  has_many :communication_documents, :dependent => :destroy
  accepts_nested_attributes_for :communication_documents
  has_many :communication_communicants, :dependent => :destroy
  has_many :communicants, :through => :communication_communicants
  accepts_nested_attributes_for :communicants

  default_scope { order('date DESC') }

  def as_json(options = {})
    super(:methods => [ :formatted_date, :user, :attached_documents, :communicants])
  end

  def attached_documents
    communication_documents
  end

  def formatted_date
    date&.strftime(Complaint::DateFormat)
  end

  def formatted_date=(val)
    write_attribute(:date, Date.parse(val))
  end
end
