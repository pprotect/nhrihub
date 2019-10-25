class Project < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  has_many :project_project_areas, :dependent => :destroy
  has_many :project_areas, :through => :project_project_areas
  has_many :project_project_subareas, :dependent => :destroy
  has_many :project_subareas, :through => :project_project_subareas
  belongs_to :mandate # == areas
  has_many :project_performance_indicators, :dependent => :destroy
  has_many :performance_indicators, :through => :project_performance_indicators
  has_many :reminders, :as => :remindable, :autosave => true, :dependent => :destroy
  has_many :notes, :as => :notable, :autosave => true, :dependent => :destroy
  has_many :project_documents, :dependent => :destroy
  has_many :named_project_documents, ->{merge(ProjectDocument.named)}, :class_name => 'ProjectDocument', :dependent => :destroy
  accepts_nested_attributes_for :project_documents

  accepts_nested_attributes_for :project_performance_indicators
  alias_method :performance_indicator_associations_attributes=, :project_performance_indicators_attributes=

  # name was changed in the UI, but model name was not changed as there is an Area model already
  alias_method :area_ids=, :project_area_ids=
  alias_method :area_ids, :project_area_ids
  alias_method :areas, :project_areas
  alias_method :areas=, :project_areas=
  alias_method :subareas, :project_subareas
  alias_method :subareas=, :project_subareas=
  alias_method :subarea_ids=, :project_subarea_ids=
  alias_method :subarea_ids, :project_subarea_ids

  def self.selected_by_url(params)
    if title = params[:title]
      with_title(title)
    else
      all
    end
  end

  def self.filtered(query)
    with_title(query[:title]).
      with_mandate(query[:mandate_ids]).
      with_subareas(query[:subarea_ids]).
      with_performance_indicators(query[:performance_indicator_ids])
  end

  def self.no_filter
    where("1=1")
  end

  def self.filter_all
    where("1=0")
  end

  def self.pg_esc(string)
    string.gsub(/('|\?|\[|\\|\)|\()/,'\\\\\1')
  end

  def self.with_title(title_fragment)
    return no_filter if(title_fragment.blank?)
    where("\"projects\".\"title\" ~* '.*#{pg_esc(title_fragment)}.*'")
  end

  def self.with_mandate(mandate_ids)
    matches_mandate_filter(mandate_ids).or(undesignated_mandate(mandate_ids))
  end

  def self.matches_mandate_filter(mandate_ids)
    where(mandate_id: mandate_ids)
  end

  def self.undesignated_mandate(mandate_ids)
    if mandate_ids.delete_if(&:blank?).map(&:to_i).include?(0)
      where(mandate_id: nil)
    else
      where("1=0")
    end
  end

  def self.with_subareas(subarea_ids)
    return filter_all if subarea_ids.delete_if(&:blank?).empty?
    #matches_subareas_filter(subarea_ids).or(undesignated_subarea(subarea_ids))
    subquery_select_subareas = <<-SQL.squish
      select "projects"."id"
      from projects
      join project_project_subareas
      on project_project_subareas.project_id = projects.id
      where project_project_subareas.subarea_id in (#{subarea_ids.join(',')})
    SQL
    subquery_match_subareas = "\"projects\".\"id\" in (#{subquery_select_subareas})"
    subquery_any_subareas = <<-SQL.squish
      SELECT "project_project_subareas".*
        FROM "project_project_subareas"
        WHERE "projects"."id" = "project_project_subareas"."project_id"
    SQL
    if subarea_ids.map(&:to_i).include?(0)
      Project.where("(#{subquery_match_subareas}) OR NOT (EXISTS (#{subquery_any_subareas }))")
    else
      Project.where("(#{subquery_match_subareas})")
    end
    #where.not(ProjectProjectSubarea.where("project_project_subareas.project_id = projects.id").arel.exists)
  end

  def self.with_performance_indicators(performance_indicator_ids)
    return filter_all if performance_indicator_ids.delete_if(&:blank?).empty?
    joins(:project_performance_indicators).where("project_performance_indicators.performance_indicator_id" => performance_indicator_ids).distinct
  end

  def as_json(options={})
    super( :methods => [
      :id, :title, :description, :subarea_ids, :area_subarea_ids,
      :mandate_id, :reminders, :notes, :project_documents, :performance_indicator_associations
    ])
  end

  def area_subarea_ids
    project_subareas.inject({}) do |hash, subarea|
      area_id = subarea.area_id
      hash[area_id] = hash[area_id] || []
      hash[area_id] << subarea.id
      hash
    end
  end

  def performance_indicator_associations
    project_performance_indicators
  end

  # overwrite the AR method for special treatment of named documents
  def save
    if named_project_documents.length #there are existing named docs
      new_doc_titles = project_documents.reject(&:persisted?).map(&:title)
      # delete any existing named docs that are being added with this update
      named_project_documents.
        select { |doc| new_doc_titles.include? doc.title }.
        each { |doc| doc.destroy }
    end
    super
  end

  def notable_url(notable_id)
    project_note_path('en',id,notable_id)
  end

  def remindable_url(remindable_id)
    project_reminder_path('en',id,remindable_id)
  end

  def index_url
    projects_url(:en, {:host => SITE_URL, :protocol => 'https', :title => title})
  end

  def index_path
    projects_path(:en, {:title => title})
  end

end
