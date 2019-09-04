class MediaAppearance < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include FileConstraints
  include RemoveAttachedFile
  ConfigPrefix = 'media_appearance'

  belongs_to :user
  has_many :reminders, :as => :remindable, :dependent => :destroy
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :media_areas, :dependent => :destroy
  has_many :areas, ->{ where(:type => 'MediaIssueArea') }, :through => :media_areas
  has_many :media_subareas, :dependent => :destroy
  has_many :subareas, ->{ where(:type => 'MediaIssueSubarea') }, :through => :media_subareas
  has_many :media_appearance_performance_indicators, :dependent => :destroy
  has_many :performance_indicators, :through => :media_appearance_performance_indicators
  accepts_nested_attributes_for :media_appearance_performance_indicators
  alias_method :performance_indicator_associations_attributes=, :media_appearance_performance_indicators_attributes=

  has_one_attached :file

  default_scope { order('media_appearances.created_at desc') }

  before_save NullStringConvert

  def as_json(options={})
    super({:except => [:updated_at,
                       :created_at],
           :methods=> [:date,
                       :has_link,
                       :has_scanned_doc,
                       :collection_item_areas,
                       :area_ids,
                       :subarea_ids,
                       :performance_indicator_associations,
                       :reminders,
                       :notes,
                       :create_reminder_url,
                       :create_note_url]})
  end

  # assign a generic name so that javascript is reusable for different collections
  alias_method :collection_item_areas, :media_areas

  def performance_indicator_associations
    media_appearance_performance_indicators
  end

  def page_data
    MediaAppearance.all
  end

  def create_url
    media_appearances_path(:en)
  end

  def create_note_url
    media_appearance_notes_path(:en,id) if persisted?
  end

  def create_reminder_url
    media_appearance_reminders_path(:en,id) if persisted?
  end

  def url
    media_appearance_path(:en,id) if persisted?
  end

  def notable_url(notable_id)
    media_appearance_note_path('en',id,notable_id)
  end

  def remindable_url(remindable_id)
    media_appearance_reminder_path('en',id,remindable_id)
  end

  # used in reminder mailer
  def index_url
    media_appearances_url(:en, {:host => SITE_URL, :protocol => 'https', :title => title})
  end

  def index_path
    media_appearances_path(:en, {:title => title})
  end

  def date
    created_at.to_time.to_date.to_s(:default) if persisted? # to_time converts to localtime
  end

  def has_link
    !article_link.blank?
  end

  def has_scanned_doc
    file.attached?
  end

end
