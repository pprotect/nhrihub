class DistrictMunicipality < ActiveRecord::Base
  belongs_to :province
  has_many :local_municipalities, foreign_key: :district_id

  def as_json(options={})
    super(except: [:created_at, :updated_at], methods: [:type, :local_municipalities])
  end

  def type
    self.class.to_s
  end
end
