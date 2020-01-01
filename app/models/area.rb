class Area < ActiveRecord::Base
  has_many :subareas, :dependent => :delete_all

  DefaultNames = ["Human Rights", "Good Governance", "Special Investigations Unit", "Corporate Services"]

  def as_json(opts = {})
    super(:except => [:created_at, :updated_at], :methods => [:subareas, :url, :key])
  end

  def key
    name.downcase.gsub(/\s+/,'_')
  end
end
