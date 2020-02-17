class Province < ActiveRecord::Base
  has_many :provincial_agencies
  has_many :district_municipalities
  has_many :metropolitan_municipalities

  def municipalities
    district_municipalities + metropolitan_municipalities
  end

  def as_json(options={})
    super(except: [:created_at, :updated_at], methods:[:district_municipalities, :metropolitan_municipalities])
  end
end
