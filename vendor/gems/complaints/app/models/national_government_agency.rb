class NationalGovernmentAgency < Agency
  def as_json(options={})
    super(except: [:created_at, :updated_at, :code], methods: [:type, :description])
  end

  def classification
    "National Government Agencies"
  end

  def agency_select_params
    {top_level_category: 'national',
     national_agency_type: 'government_agencies',
     selected_national_agency_id: id }
  end
end
