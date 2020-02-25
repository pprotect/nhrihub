class DemocracySupportingStateInstitution < Agency

  def as_json(options={})
    super(except: [:created_at, :updated_at, :code], methods: [:type, :description])
  end

  def description
   name
  end

  def agency_select_params
    {top_level_category: 'national',
     national_agency_type: 'democracy_institutions',
     selected_national_agency_id: id }
  end
end
