class StatusChange < ActiveRecord::Base
  belongs_to :user
  belongs_to :complaint
  belongs_to :complaint_status
  accepts_nested_attributes_for :complaint_status

  scope :most_recent_for_complaint, ->{
    sc = StatusChange.arel_table
    sc1 = sc.alias
    subquery = sc[:change_date].eq(sc.project(sc1[:change_date].maximum).
                                   from(sc1).
                                   where(sc1[:complaint_id].eq(sc[:complaint_id]))
                                )
    where(subquery)
  }

  def as_json(options={})
    super(:only => [], :methods => [:user_name, :date, :status_humanized])
  end

  def user_name
    # normally there should always be an associated user, but imported data may not have one
    user && user.first_last_name
  end

  def date
    change_date
  end

  def status_humanized
    complaint_status.name
  end

  def status_humanized=(val)
    complaint_status.name = (val)
  end

end
