class Assign < ActiveRecord::Base
  belongs_to :complaint
  belongs_to :assignee, :class_name => 'User', :foreign_key => :user_id

  # most recent first
  #default_scope -> { order(:created_at => :desc)}

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

  def notify_assignee
    assignee.complaint_assignment_notify(complaint)
  end

  def as_json(options = {})
    super(:only => [], :methods => [:date, :name])
  end

  def date
    created_at.localtime.to_date.to_s(:short)
  end

  def name
    assignee.first_last_name
  end
end
