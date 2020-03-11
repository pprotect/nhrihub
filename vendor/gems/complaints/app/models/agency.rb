class Agency < ActiveRecord::Base
  has_many :complaint_agencies, :dependent => :destroy
  has_many :complaints, :through => :complaint_agencies

  default_scope ->{ order('name').where("name not like 'Unassigned'") }

  def self.hierarchy
    {national: national,
     provincial: provincial,
     local: local}
  end

  NationalTypes        = ['NationalGovernmentAgency', 'NationalGovernmentInstitution', 'DemocracySupportingStateInstitution']
  ProvincialTypes      = ['ProvincialAgency']
  LocalTypes           = ["MetropolitanMunicipality", "LocalMunicipality"]
  MetroProvincialTypes = ["MetropolitanMunicipality", "ProvincialAgency"] # they both are classified by province

  def self.national
    where(type: NationalTypes).group_by(&:type)
  end

  def self.provincial
    where(type: ProvincialTypes).group_by(&:province_id)
  end

  def self.local
    where(type: LocalTypes).
      group_by(&:province_id).inject({}) do |h,(province_id, municipalities)|
        h[province_id] = municipalities.group_by{|m| m.district_id || 0 } # 0 id will connote MetropolitanMunicipality
        h
      end
  end

  def self.classified
    local_municipalities = LocalMunicipality.includes(district_municipality: :province)
    metro_provincial     = Agency.where(type: MetroProvincialTypes).includes(:province)
    national_agencies    = Agency.where(type: NationalTypes)
    (national_agencies + metro_provincial + local_municipalities).
      group_by(&:classification).
      collect{|k,v| {classification: k, agencies: v}}
  end

  def self.unassigned_first
    unscoped.
      select("*, case when name='Unassigned' then 1 else 2 end as unassigned_first").
      order([:unassigned_first, :name])
  end

  def as_json(options={})
    if options.blank?
      super(:except => [:created_at, :updated_at, :code], :methods => [:selected, :type])
    else
      super options
    end
  end

  def self.top_level_grouping
    {national: national, provincial: provincial, local: local}
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
