class IccReferenceDocument < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include FileConstraints
  include DocumentApi
  ConfigPrefix = 'nhri.icc_reference_documents'

  belongs_to :user
  alias_method :uploaded_by, :user
  has_many :reminders, :as => :remindable, :dependent => :destroy

  has_one_attached :file

  before_save do |doc|
    if doc.title.blank?
      doc.title = doc.original_filename.split('.')[0]
    end
  end

  after_destroy do |doc|
    # without this, ActiveStorage naturally invokes purge_later
    # which removes the file, but the uncertain delay (later)
    # is problematic for testing
    doc.file.purge
  end

  def as_json(options = {})
    super(:except  => [:created_at, :updated_at],
          :methods => [:uploaded_by,
                       :formatted_creation_date,
                       :formatted_filesize,
                       :reminders] )
  end

  def remindable_url(remindable_id)
    nhri_icc_reference_document_reminder_path('en',id,remindable_id)
  end

  def index_url
    nhri_icc_reference_documents_url('en', {:host => SITE_URL, :protocol => 'https', :selected_document_id => id})
  end
end
