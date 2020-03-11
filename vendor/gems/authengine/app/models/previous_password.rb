class PreviousPassword < ActiveRecord::Base
  belongs_to :user

  # new p/w is checked against the prior one in the users table and the 11 before that in the previous_passwords table
  MaximumPreviousPasswordCount = 11

  after_create :discard_excess

  def self.add(user_id, crypted_password)
    create(user_id: user_id, crypted_password: crypted_password)
  end

  private
  def discard_excess
    ids = PreviousPassword.where(user_id: user_id).order(created_at: :desc).pluck(:id)
    excess_ids = ids.drop(MaximumPreviousPasswordCount)
    PreviousPassword.delete_by(id: excess_ids) unless excess_ids.empty?
  end
end
