class DistrictMunicipality < ActiveRecord::Base
  belongs_to :province
  has_many :local_municipalities, foreign_key: :district_id

  def as_json(options={})
    if options.blank?
      super(except: [:created_at, :updated_at], methods: [:type, :local_municipalities, :description, :selection_vector])
    else
      super options
    end
  end

  def type
    self.class.to_s
  end

  def description
    "#{name} district (in #{province.name} province)"
  end

  def selection_vector
    {top_level_category: 'municipalities',
     selected_province_id: province_id,
     agency_id: id }
  end
end
