class ComplaintTransfer < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :transferee, class_name: :Office, foreign_key: :office_id

  def as_json(options={})
    super(:except => [:updated_at, :created_at, :id],
          :methods => [:date, :event_description, :event_label])
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
