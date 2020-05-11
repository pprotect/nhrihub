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

  def self.provincial(group_by = 'province_id')
    includes(:province).where(type: ProvincialTypes).group_by{|p| p.send(group_by) }
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
      super(:except => [:created_at, :updated_at, :code], :methods => [:selected, :type, :agency_select_params, :description])
    else
      super options
    end
  end

  def self.top_level_grouping
    {national: national, provincial: provincial, local: local}
  end

  def self.national_hierarchy
    national.map{|k,v| {type: k, name: k.tableize.humanize.titlecase, collection: v}}
  end

  def self.provincial_hierarchy
    provincial('province_name').sort.map{|k,v| {id: v.first.province_id, type: 'ProvincialAgency', name: k, collection: v}}
  end

  def self.local_hierarchy
    provinces = Province.pluck(:id,:name).sort.collect do |id,name|
      { name: name,
        id: id,
        collection: [{name: "DistrictMunicipalities", collection: []},
                     {name: "MetropolitanMunicipalities", collection: []}]
      }
    end

    district_collection = LocalMunicipality.includes(district_municipality: :province).all.
      group_by(&:district_municipality).
      inject(provinces) do |h,(district,local_municipalities)|
        district_municipalities = h.find{|m| m[:name]==district.province.name}[:collection].find{|c| c[:name] == "DistrictMunicipalities"}
        district_collection = {district_id: district.id, name: district.name, collection: local_municipalities.map{|lm|{name: lm.name}}}
        district_municipalities[:collection] << district_collection
        h
    end

    collection = MetropolitanMunicipality.includes(:province).all.
      inject(district_collection) do |h,mm|
        metropolitan_municipalities = h.find{|m| m[:name]==mm.province.name}[:collection].find{|c| c[:name] == "MetropolitanMunicipalities"}
        metropolitan_municipalities[:collection] << {name: mm.name}
        h
      end
  end

  def self.hierarchy
    ['National', 'Provincial', 'Local'].collect do |type|
      {name: type, collection: self.send("#{type.downcase}_hierarchy")}
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
