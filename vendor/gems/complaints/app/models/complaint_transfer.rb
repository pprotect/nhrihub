class ComplaintTransfer < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :transferee, class_name: :Office, foreign_key: :office_id
  belongs_to :user

  scope :most_recent_for_complaint, ->{
    ct = ComplaintTransfer.arel_table
    ct1 = ct.alias
    subquery = ct[:created_at].eq(ct.project(ct1[:created_at].maximum).
                                   from(ct1).
                                   where(ct1[:complaint_id].eq(ct[:complaint_id]))
                                )
    where(subquery)
  }

  def as_json(options={})
    super(:except => [:updated_at, :created_at, :id],
          :methods => [:date, :event_description, :event_label, :user_name])
  end

  def user_name
    user&.first_last_name
  end

  def date
    created_at
  end

  def event_description
    transferee.name
  end

  def as_timeline_event
    TimelineEvent.new(self)
  end

  def event_label
    "Transferred to"
  end
end
