class PreviousPassword < ActiveRecord::Base
  belongs_to :user
  MaximumPreviousPasswordCount = 12

  after_create :discard_excess

  def self.add(user_id, crypted_password)
    create(user_id: user_id, crypted_password: crypted_password)
  end

  private
  def discard_excess
    ids = PreviousPassword.where(user_id: user_id).order(created_at: :desc).pluck(:id)
    excess_ids = ids.drop(MaximumPreviousPasswordCount)
    PreviousPassword.where(id: excess_ids).delete_all unless excess_ids.empty?
  end
end
