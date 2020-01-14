class OfficeGroup < ActiveRecord::Base
  has_many :offices, dependent: :destroy

  def url
    Rails.application.routes.url_helpers.office_group_path(:en,id) if persisted?
  end

  def as_json(options = {})
    super(:include => {:offices => {:except => [:created_at, :updated_at], :methods => [:url]}}, methods: [:url], :except => [:created_at, :updated_at])
  end
end
