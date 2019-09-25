class Mandate < ActiveRecord::Base
  Names = ["Corporate Services", "Good Governance", "Human Rights", "Special Investigations Unit"]
  Keys = ['strategic_plan', 'good_governance', 'human_rights', 'special_investigations_unit']

  has_many :projects
  has_many :complaints

  scope :good_governance,    ->{ where(:key => "good_governance") }
  scope :human_rights,       ->{ where(:key => "human_rights") }
  scope :siu,                ->{ where(:key => "special_investigations_unit") }
  scope :strategic_plan, ->{ where(:key => "strategic_plan") }

  def as_json(options = {})
    options = {:only => [:id, :key], :methods => [:name]} if options.blank?
    super(options)
  end

  def name
    I18n.t("activerecord.models.mandate.keys.#{key}")
  end
end
