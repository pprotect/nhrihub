class LocalMunicipality < Agency
  belongs_to :district_municipality, foreign_key: :district_id

  def as_json(options={})
    super(except: [:created_at, :updated_at, :code])
  end
end
