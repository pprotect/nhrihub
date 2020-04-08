class OfficeGroup < ActiveRecord::Base
  has_many :offices, dependent: :destroy

  scope :head_office, ->{ where("office_groups.name ilike 'head%' ") }
  scope :regional_provincial, ->{ where("office_groups.name not ilike 'head%' ") }
  scope :national_regional_provincial, ->{ where("office_groups.name is not null") }
  scope :regional, ->{ where(name: "Regional Offices") }

  def provincial?
    name=~/provinc/i
  end

  def regional?
    name=~/region/i
  end

  def url
    Rails.application.routes.url_helpers.office_group_path(:en,id) if persisted?
  end

  def as_json(options = {})
    super(:include => {:offices => {:except => [:created_at, :updated_at], :methods => [:url]}}, methods: [:url], :except => [:created_at, :updated_at])
  end
end
