class ProvincialAgency < Agency
  belongs_to :province

  def classification
    "#{province.name} Provincial Agencies"
  end

  def as_json(options={})
    super(except: [:created_at, :updated_at, :code], methods: [:type, :description])
  end

  def description
    "#{province.name} province, #{name} Provincial Agency"
  end

  def province_name
    province.name
  end

  def agency_select_params
    {top_level_category: 'provincial_agencies',
     selected_province_id: province_id,
     provincial_agency_id: id }
  end
end