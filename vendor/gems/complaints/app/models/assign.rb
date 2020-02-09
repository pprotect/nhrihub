class Assign < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :assignee, :class_name => 'User', :foreign_key => :user_id
  belongs_to :assigner, :class_name => 'User', :foreign_key => :assigner_id

  scope :for_assignee, ->(id){ where("assigns.user_id = ?", id) }

  scope :single_complaint_most_recent, ->{
    a = Assign.arel_table
    a1 = a.alias
    subquery = a[:created_at].eq(a.project(a1[:created_at].maximum).
                                   from(a1).
                                   where(a1[:complaint_id].eq(a[:complaint_id]))
                                )
    where(subquery)
  }

  scope :most_recent_for_assignee, ->(id){ single_complaint_most_recent.for_assignee(id) }

  def as_timeline_event
    TimelineEvent.new(self)
  end

  def event_label
    "Assigned to"
  end

  def notify_assignee
    assignee.complaint_assignment_notify(complaint)
  end

  def as_json(options = {})
    super(:only => [],
          :methods => [:user_name, :date, :event_description, :event_label])
  end
  #shows as "Event_label: event_description (by user_name on date)"

  def user_name
    assigner&.first_last_name
  end

  def date
    created_at.localtime
  end

  def event_description
    assignee.first_last_name
  end
end
