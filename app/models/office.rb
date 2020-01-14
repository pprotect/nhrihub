class Office < ActiveRecord::Base
  belongs_to :office_group
  def as_json(options={})
    super(except: [:created_at, :updated_at], methods: [:url])
  end

  def url
    Rails.application.routes.url_helpers.office_group_office_path(:en,office_group_id,id) if persisted?
  end
end
