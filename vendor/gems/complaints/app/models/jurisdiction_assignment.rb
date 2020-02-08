class JurisdictionAssignment < ActiveRecord::Base
  belongs_to :user
  belongs_to :branch, ->{ joins(:office_group).merge(OfficeGroup.head_office) }, class_name: "Office"
  belongs_to :complaint

  scope :most_recent_for_complaint, ->{
    ja = JurisdictionAssignment.arel_table
    ja1 = ja.alias
    subquery = ja[:created_at].eq(ja.project(ja1[:created_at].maximum).
                                   from(ja1).
                                   where(ja1[:complaint_id].eq(ja[:complaint_id]))
                                )
    where(subquery)
  }

  def as_json(options={})
    super(:except => [:updated_at, :created_at, :id, :user_id, :end_date, :complaint_id],
          :methods => [:change_date, :user_name, :date, :event_description, :event_label])
  end

  def event_description(*args)
    branch&.name
  end

  def as_timeline_event
    TimelineEvent.new(self)
  end

  def change_date
    created_at
  end

  def date
    created_at
  end

  def event_label
    "Jurisdiction assigned"
  end

  def user_name
    # normally there should always be an associated user, but imported data may not have one
    user&.first_last_name
  end

end
