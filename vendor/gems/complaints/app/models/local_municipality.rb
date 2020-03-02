class LocalMunicipality < Agency
  belongs_to :district_municipality, foreign_key: :district_id

  def as_json(options={})
    super(except: [:created_at, :updated_at, :code], methods: [:type, :agency_select_params, :agency_id, :description])
  end

  def agency_select_params
    {top_level_category: 'municipalities',
     selected_province_id: district_municipality.province_id,
     selected_id: district_id,
     agency_id: id }
  end

  def classification
    "#{district_municipality.province.name} Province, local municipalities"
  end

  def description
    "#{district_municipality.province.name} province, #{district_municipality.name} district, #{name} municipality"
  end

  def agency_id
   id
  end
end
