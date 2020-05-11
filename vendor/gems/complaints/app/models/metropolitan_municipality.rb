class MetropolitanMunicipality < Agency
  belongs_to :province
  belongs_to :district_municipality, foreign_key: nil # facilitates eager loading of disparate agency types

  def as_json(options={})
    if options.blank?
      super(except: [:created_at, :updated_at, :code], methods: [:type, :description])
    else
      super options
    end
  end

  def province_name
    province.name
  end

  def description
    "#{name} metropolitan municipality (in #{province.name} province)"
  end

  def classification
    "#{province.name} Metropolitan Municipalities"
  end

  def agency_select_params
    {top_level_category: 'municipalities',
     selected_province_id: province_id,
     selected_id: id }
  end
end
