class Mandate < ActiveRecord::Base
  DefaultNames = ["Corporate Services", "Good Governance", "Human Rights", "Special Investigations Unit"]

  has_many :projects
  has_many :complaints

  scope :good_governance,    ->{ where(:name => "Good Governance") }
  scope :human_rights,       ->{ where(:name => "Human Rights") }
  scope :siu,                ->{ where(:name => "Special Investigations Unit") }
  scope :strategic_plan, ->{ where(:name => "Corporate Services") }

  def as_json(options = {})
    options = {:only => [:id, :name], :methods => [:key]} if options.blank?
    super(options)
  end

  def key
    name.titlecase.unspaced.underscore
  end
end
