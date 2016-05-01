class Mandate < ActiveRecord::Base
  has_many :project_mandates, :dependent => :destroy
  has_many :projects, :through => :project_mandates
  has_many :project_types, :dependent => :destroy

  scope :project_types_for_project, ->(id){
    # alias the name attribute to avoid collision with the Mandate#name method
    select("project_types.name as type_name, project_types.id as type_id, mandates.key").
    joins(:project_types => :project_project_types).
    where("project_project_types.project_id = ?",id)
  }

  # this is the form of the result we expect
  # [{"name"=>"mandate name", "types"=>[{"id"=>1, "name"=>"type name"}]}]
  def self.project_types_for(project_id)
    project_types_for_project(project_id).
    group_by(&:name). # this is why we return Mandate objects, so we can use the #name method
    map{|name,v| {:name => name, :types => v.map{|vv| {:name => vv.type_name,:id=> vv.type_id}}}}
  end

  def as_json(options = {})
    super(:only => [:id, :key], :methods => [:name, :project_types])
  end

  def name
    I18n.t("activerecord.models.mandate.keys.#{key}")
  end
end