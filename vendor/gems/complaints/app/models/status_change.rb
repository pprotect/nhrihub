class StatusChange < ActiveRecord::Base
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

  def duration
    end_time = end_date.nil? ? Time.now : end_date
    # see lib/rails_class_extensions.rb
    end_time.distance_of_time_in_words(change_date)
  end

  def as_json(options={})
    super(:except => [:updated_at, :created_at, :id, :user_id, :end_date, :complaint_id],
          :methods => [:change_date, :user_name, :date, :status_humanized])
  end

  def user_name
    # normally there should always be an associated user, but imported data may not have one
    user&.first_last_name
  end

  def date
    change_date
  end

  def status_humanized
    [complaint_status&.name, close_memo].
      delete_if(&:blank?).
      join(', ')
  end

  def status_humanized=(val)
    complaint_status.name = (val)
  end

end
