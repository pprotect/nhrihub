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
