class StatusChange < ActiveRecord::Base
  enum status_memo_type: {non_existent: 0, close_preset: 1, close_referred_to:2, close_other_reason: 3, assessment: 4}
  belongs_to :user
  belongs_to :complaint
  belongs_to :complaint_status
  accepts_nested_attributes_for :complaint_status

  #default_scope { order(change_date: :desc) }
  scope :most_recent_first, -> { order(change_date: :desc) }

  before_create do
    self.change_date ||= Time.now
    if complaint&.status_changes&.count && complaint.status_changes.count > 0
      previous = complaint.status_changes.merge(StatusChange.most_recent_for_complaint).first
      previous.update(end_date: change_date)
    end
  end

  scope :most_recent_for_complaint, ->{
    sc = StatusChange.arel_table
    sc1 = sc.alias
    subquery = sc[:change_date].eq(sc.project(sc1[:change_date].maximum).
                                   from(sc1).
                                   where(sc1[:complaint_id].eq(sc[:complaint_id]))
                                )
    where(subquery)
  }

  def as_timeline_event
    TimelineEvent.new(self)
  end

  def duration
    end_time = end_date.nil? ? Time.now : end_date
    # see lib/rails_class_extensions.rb
    end_time.distance_of_time_in_words(change_date)
  end

  def as_json(options={})
    super(:except => [:updated_at, :created_at, :id, :user_id, :end_date, :complaint_id],
          :methods => [:user_name, :date, :event_description, :event_label])
  end

  def event_label
    if initial_status_for_complaint?
      "Initial status"
    else
      "Status change"
    end
  end

  def initial_status_for_complaint
    subquery=<<-SQL.squish
      select min(sc.change_date) change_date
      from status_changes sc where sc.complaint_id=#{complaint_id}
    SQL
    query = <<-SQL.squish
      status_changes.complaint_id =#{complaint_id}
      and status_changes.change_date = (#{subquery})
    SQL
    StatusChange.where(query).select("status_changes.id").first
  end

  def initial_status_for_complaint?
    id == initial_status_for_complaint.id
  end

  def user_name
    # normally there should always be an associated user, but imported data may not have one
    user&.first_last_name
  end

  def date
    change_date
  end

  def event_description
    [complaint_status&.name, status_memo].
      delete_if(&:blank?).
      join(', ')
  end

  def event_description=(val)
    complaint_status.name = (val)
  end

end
