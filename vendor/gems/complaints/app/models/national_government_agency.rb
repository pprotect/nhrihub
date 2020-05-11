class NationalGovernmentAgency < Agency
  belongs_to :province, foreign_key: nil # facilitates eager loading of disparate agency types
  belongs_to :district_municipality, foreign_key: nil # facilitates eager loading of disparate agency types

  def as_json(options={})
    if options.blank?
      super(except: [:created_at, :updated_at, :code], methods: [:type, :description])
    else
      super options
    end
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
