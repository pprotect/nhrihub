class NationalGovernmentInstitution < Agency
  def as_json(options={})
    super(except: [:created_at, :updated_at, :code], methods: [:type, :description])
  end

  alias_attribute :description, :name

  def classification
    "National Government Institutions"
  end

  def agency_select_params
    {top_level_category: 'national',
     national_agency_type: 'government_institutions',
     selected_national_agency_id: id }
  end
end
