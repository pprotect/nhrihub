class MetropolitanMunicipality < Agency
  belongs_to :province

  def as_json(options={})
    super(except: [:created_at, :updated_at, :code], methods: [:type])
  end
end
