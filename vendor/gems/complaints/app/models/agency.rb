class Agency < ActiveRecord::Base
  has_many :complaint_agencies, :dependent => :destroy
  has_many :complaints, :through => :complaint_agencies

  default_scope ->{ order('name').where("name not like 'Unassigned'") }

  def self.unassigned_first
    unscoped.
      select("*, case when name='Unassigned' then 1 else 2 end as unassigned_first").
      order([:unassigned_first, :name])
  end

  def as_json(options={})
    if options.blank?
      super(:except => [:created_at, :updated_at], :methods => [:selected])
    else
      super options
    end
  end

  def selected
    true
  end

  def description
    full_name ?  "#{full_name}, (#{name})" : name
  end

  def delete_allowed
    complaints.count.zero?
  end
end
