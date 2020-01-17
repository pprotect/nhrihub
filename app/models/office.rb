class Office < ActiveRecord::Base
  belongs_to :office_group
  belongs_to :province

  scope :branches, ->{ joins(:office_group).merge(OfficeGroup.head_office) }
  scope :not_branches, -> { joins(:office_group).merge(OfficeGroup.not_head_office) }

  def as_json(options={})
    super(except: [:created_at, :updated_at], methods: [:url])
  end

  def url
    Rails.application.routes.url_helpers.office_group_office_path(:en,office_group_id,id) if persisted?
  end

  def name
    if province_id
      province.name
    else
      read_attribute(:name)
    end
  end
end
