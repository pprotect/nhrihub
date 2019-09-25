class Nhri::AdvisoryCouncil::AdvisoryCouncilIssue < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include FileConstraints
  include RemoveAttachedFile
  ConfigPrefix = 'nhri.advisory_council_issue'

  has_one_attached :file

  belongs_to :user
  belongs_to :mandate
  has_many :reminders, :as => :remindable, :dependent => :destroy
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :advisory_council_issue_issue_areas, :dependent => :destroy
  has_many :advisory_council_issue_areas, :through => :advisory_council_issue_issue_areas
  has_many :advisory_council_issue_issue_subareas, :dependent => :destroy
  has_many :advisory_council_issue_subareas, :through => :advisory_council_issue_issue_subareas

  default_scope {order(:created_at => :desc)}

  before_save NullStringConvert

  def as_json(options={})
    super({:except => [:updated_at,
                       :created_at],
           :methods=> [:date,
                       :has_link,
                       :has_scanned_doc,
                       :area_ids,
                       :subarea_ids,
                       :area_subarea_ids,
                       :reminders,
                       :notes,
                       :url,
                       :initiator,
                       :create_reminder_url,
                       :create_note_url]})
  end

  alias_method :area_ids, :advisory_council_issue_area_ids
  alias_method :subarea_ids, :advisory_council_issue_subarea_ids

  # value comes in from shared js and is ignored
  attr_writer :performance_indicator_ids

  def area_subarea_ids
    advisory_council_issue_subareas.inject({}) do |hash, subarea|
      area_id = subarea.area_id
      hash[area_id] = hash[area_id] || []
      hash[area_id] << subarea.id
      hash
    end
  end

  def initiator
    user.first_last_name if user
  end

  def url
    nhri_advisory_council_issue_path(:en,id) if persisted?
  end

  def create_url
    nhri_advisory_council_issues_path(:en)
  end

  def create_note_url
    nhri_advisory_council_advisory_council_issue_notes_path(:en,id) if persisted?
  end

  def create_reminder_url
    nhri_advisory_council_advisory_council_issue_reminders_path(:en,id) if persisted?
  end

  def has_link
    !article_link.blank?
  end

  def has_scanned_doc
    file.attached?
  end

  def date
    created_at.to_time.to_date.to_s(:default) if persisted? # to_time converts to localtime
  end

  def notable_url(notable_id)
    nhri_advisory_council_advisory_council_issue_note_path('en',id,notable_id)
  end

  def remindable_url(remindable_id)
    nhri_advisory_council_advisory_council_issue_reminder_path('en',id,remindable_id)
  end

  def index_url
    nhri_advisory_council_issues_url('en',{:host => SITE_URL, :protocol => 'https', :selection => title})
  end

end
