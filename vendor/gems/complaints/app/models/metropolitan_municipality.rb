class MetropolitanMunicipality < Agency
  belongs_to :province

  def as_json(options={})
    super(except: [:created_at, :updated_at, :code], methods: [:type, :description])
  end

  def description
    "#{province.name} province, #{name} metropolitan municipality"
  end

  def agency_select_params
    {top_level_category: 'municipalities',
     selected_province_id: province_id,
     selected_id: id }
  end

end
