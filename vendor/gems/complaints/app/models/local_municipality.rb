class LocalMunicipality < Agency
  belongs_to :district_municipality, foreign_key: :district_id
  belongs_to :province, foreign_key: nil # facilitates eager loading of disparate agency types
  alias_attribute :agency_id, :id

  def as_json(options={})
    if options.blank?
      super(except: [:created_at, :updated_at, :code], methods: [:type, :agency_select_params, :agency_id, :description])
    else
      super options
    end
  end

  def agency_select_params
    {top_level_category: 'municipalities',
     selected_province_id: district_municipality.province_id,
     selected_id: district_id,
     agency_id: id }
  end

  def province_name
    district_municipality.province.name
  end

  def classification
    "#{district_municipality.province.name} Province, local municipalities"
  end

  def description
    "#{name} municipality (in #{district_municipality.province.name} province, #{district_municipality.name} district)"
  end
end
