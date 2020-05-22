class DemocracySupportingStateInstitution < Agency
  belongs_to :province, foreign_key: nil # facilitates eager loading of disparate agency types
  belongs_to :district_municipality, foreign_key: nil # facilitates eager loading of disparate agency types

  def as_json(options={})
    if options.blank?
      super(except: [:created_at, :updated_at, :code], methods: [:type, :description, :selection_vector])
    else
      super options
    end
  end

  def description
   name
  end

  def classification
    "Democracy-Supporting Government Institutions"
  end

  def selection_vector
    {top_level_category: 'national',
     national_agency_type: 'democracy_institutions',
     selected_national_agency_id: id }
  end
end
