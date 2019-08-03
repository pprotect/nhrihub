class StatusChange < ActiveRecord::Base
  belongs_to :user
  belongs_to :complaint
  belongs_to :complaint_status
  accepts_nested_attributes_for :complaint_status

  scope :most_recent_for_complaint, ->{
    sc = StatusChange.arel_table
    sc1 = sc.alias
    subquery = sc[:created_at].eq(sc.project(sc1[:created_at].maximum).
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
    #I18n.t(".activerecord.values.complaint.status.#{new_value}")
    complaint_status.name
  end

  # TODO changes in this class result from change of status from open/closed
  # to a value stored in complaint_status association
  def status_humanized=(val)
    #if val == "open"
      #self.new_value = true
    #else
      #self.new_value = false
    #end
    complaint_status.name = (val)
  end

end
