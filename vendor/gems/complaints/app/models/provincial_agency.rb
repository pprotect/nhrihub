class ProvincialAgency < Agency
  belongs_to :province
  belongs_to :district_municipality, foreign_key: nil # facilitates eager loading of disparate agency types

  def classification
    "#{province.name} Provincial Agencies"
  end

  def as_json(options={})
    if options.blank?
      super(except: [:created_at, :updated_at, :code], methods: [:type, :description, :selection_vector])
    else
      super options
    end
  end

  def description
    is_provincial_government? ?
      "#{province.name} provincial government" :
      "#{name} Provincial Agency (in #{province.name} province)"
  end

  def province_name
    province.name
  end

  def selection_vector
    {top_level_category: 'provincial_agencies',
     selected_province_id: province_id,
     provincial_agency_id: id }
  end

  def is_provincial_government?
    name.match(/Provincial government/)
  end

  def select_option_sort_criterion
    sort_field = is_provincial_government? ? "aaa"+name : name  # put Provincial government first
    sort_field.downcase # ensure e-Government is appropriately sorted
  end
end
