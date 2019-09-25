class Subarea < ActiveRecord::Base
  belongs_to :area

  DefaultNames = { "Good Governance": ["Private", "Unreasonable", "Unjust", "Failure to act",
                                     "Delayed action", "Formal", "Informal", "Out of Jurisdiction"],
                   "Special Investigations Unit": ["Unreasonable delay", "Abuse of process", "Not properly investigated"],
                   "Human Rights": ["Violation", "Education activities", "Office reports", "Universal periodic review"] + CONVENTIONS.keys,
                   "Corporate Services": [] }

  def as_json(opts={})
    super(:except => [:created_at, :updated_at, :area_id], :methods => [:url])
  end

  def extended_name
    [area.name,name].join(" ")
  end

  def self.extended
    self.includes(:area).all.collect do |sa|
      sa.
        attributes.
        slice("id","name","full_name", "area_id").
        merge({"extended_name" => sa.extended_name})
    end
  end

  def self.hr_violation_id
    joins(:area).where("subareas.name = 'Violation' and areas.name = 'Human Rights'").pluck(:id)[0]
  end
end
