class Complainant < ActiveRecord::Base
  has_and_belongs_to_many :complaints
end
