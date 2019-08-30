class Mandate < ActiveRecord::Base
  Names = ["Corporate Services", "Good Governance", "Human Rights", "Special Investigations Unit"]
  Keys = ['strategic_plan', 'good_governance', 'human_rights', 'special_investigations_unit']

  has_many :project_mandates, :dependent => :destroy
  has_many :projects, :through => :project_mandates
  has_many :project_types, :dependent => :destroy

  has_many :complaints

  scope :good_governance,    ->{ where(:key => "good_governance") }
  scope :human_rights,       ->{ where(:key => "human_rights") }
  scope :siu,                ->{ where(:key => "special_investigations_unit") }
  scope :strategic_plan, ->{ where(:key => "strategic_plan") }

  scope :project_types_for_project, ->(id){
    # alias the name attribute to avoid collision with the Mandate#name method
    select("project_types.name as type_name, project_types.id as type_id, mandates.key").
    joins(:project_types => :project_project_types).
    where("project_project_types.project_id = ?",id)
  }

  # this is the form of the result we expect
  # [{"name"=>"mandate name", "project_types"=>[{"id"=>1, "name"=>"type name"}]}]
  def self.project_types_for(project_id)
    project_types_for_project(project_id).
    group_by(&:name). # this is why we return Mandate objects, so we can use the #name method
    map{|name,v| {:name => name, :types => v.map{|vv| {:name => vv.type_name,:id=> vv.type_id}}}}
  end

  def as_json(options = {})
    options = {:only => [:id, :key], :methods => [:name, :project_types]} if options.blank?
    super(options)
  end

  def name
    I18n.t("activerecord.models.mandate.keys.#{key}")
  end
end
